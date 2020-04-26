;;; convert a 3-digit unsigned BCD 0..199 to binary unsigned in X
d0to199	lda	#$0a	; 2	;uint16_t d0to199(uint1_t c,  // 100's
	bcc	1f	; 3	;                 uint8_t b,   // 10's
	addb	#$0a	; 2	;                 uint16_t x) { // 1's
1	mul		;11	; uint16_t d = 10*(c*10 + b); c = d & 0x80;
	abx		; 2	; return x += d & 0xff; // = c*100 + b*10;
	rts		; 5 (25);} // d0to199()

;;; convert a 3-digit signed BCD -128..127 to binary unsigned in X, signed in D
d8sgnd	bmi	d8ngtv	; 3	;int16_t d8sgnd(uint1_t n, // sign
d8pstv	jsr	d0to199	; 8 (33);               uint1_t c,  // 100's
	tfr	x,d	; 6	;               uint16_t d,  // 10's
	rts		; 2	;               uint16_t x) { // 1's
d8ngtv	jsr	d0to199	; 8 (33); return n ? d8ngtv(c, d, x) : d0to199(c, d, x);
	tfr	x,d	; 6	;} // d8sgnd()
	negb		; 2	;int16_t d8ngtv(uint1_t c,uint16_t d,uint16_t x)
	sex		; 2	;{return d = -(x += c*100 + d*10);
1	rts		; 5 (50);} // d8ngtv()

;;; multiply X -3276..3276 by 10 into D, e.g. to allow 5-digit BCD construction
x10ind	stx	,--s	; 5	;int16_t x10inD(int16_t x) {
	asl	1,s	; ?	;
	rol	,s	; ?	;
	ldd	,s	; 5	; uint16_t d = x*2;
	aslb		; 2	;
	rola		; 2	;
	aslb		; 2	;
	rola		; 2	;
	addd	,s++	; 9	; return d += d*4; // = x*10;
	rts		; 5 (38);} // x10inD()

;;; copy Y to D, convert a Y-digit unsigned BCD 0..32767 to binary unsigned in Y
d0to32k	macro
	stx	,--s	; 9	;inline uint16_t d0to32k(uint3_t y,
	ldx	#$0000	; 3	;                 const uint8_t* s) {
	sty	,--s	; 9	; uint16_t x, d = y; // digit count y <= 5
	beq	3f	; 3	;
	ldd	#$0000	; 3	;
	bra	2f	; 3	;
1	jsr	x10ind	; 8 (46); for (x = 0x0000; y; y--) {
2	leax	5,s	; 5 	;  // d is now x*10, x is now the digit pointer
	exg	d,x	; 8	;  x *= 10; // d is now the digit pointer
	ldb	d,y	; 8	;  uint8_t b = s[ /* 5[sic] + */ y]; // Y',X',PC
	abx		; 3	;  x += b;
	leay	-1,y	; 5	; }
	bne	1b	; 3	; // caller can pop d args with: leas d,s
3	tfr	x,y	; 6	;
	ldd	,s++	; 8	; return d, y = x;
	ldx	,s++	;?8(388);} // d0to32k()
	endm

;;; copy Y to D,convert a Y-digit signed BCD -32767..32767 to binary signed in Y
d16sgnd	bmi	d16ngtv	; 3	;int16_t d16sgnd(uint1_t n,
d16pstv	d0to32k		; 8(402);                uint3_t y,
	rts		; 2	;                uint8_t* s) {
d16ngtv	d0to32k		; 8(402); uint16_t x, d = y; // digit count y <= 5
	exg	y,d	; 8	; return d, x = n ? d16ngtv(y,s) : d16pstv(y,s);
	coma		; 2	;} // d16sgnd()
	comb		; 2	;int16_t d16ngtv(uint3_t y, uint8_t* s) {
	addd	#$0001	; 4	; uint16_t x, d = y; // digit count y <= 5
	exg	y,d	; 8	; return d, y = -d0to32k(y, s);
	rts		; 5(444);} // d16ngtv()

;;; convert a signed ASCII decimal integer -127..127 at X to binary in D
get3bcd	ldy	#$0000	; 4	;int16_t get3bcd(const char** x, uint16_t* y) {
	clra		; 2	; uint16_t y = 0, d;
1	jsr	peekdig	; 8 (48); uint8_t a = 0, b, s[4];
	cmpb	#'0'	; 2	;
	blo	3f	; 3	; do {
	cmpb	#'9'	; 2	;  b = peekdig(x, &a); // a is '-' if detected
	bhi	3f	; 3	;  if (b >= '0' && b <= '9') { // verified digit
	leax	1,x	; 5	;   (*x)++; // *x points to char after digit
	leay	-3,y	; 5	;
	beq	2f	; 3	;   if (y != 3) // *x points to a known digit
	leay	4,y	; 5	;
	andb	#$0f	; 2	;
	stb	,-s	; 6	;    s[y++] = b - '0';
	bra	1b	; 3	;   else
2	clrb		; 2	;    b = 0; // indicates unsuccessful conversion
	leay	3,y	; ?	;
	bra	9f	; 3	;  }
3	tstb		; 2	; } while (b);
	beq	9f	; 3	; if (b) {
	clr	,-s	; 6	;  s[y+1] = s[y]; s[y] = 0x00; // make uint16_t
	cmpy	#$0003	; 5	;  switch (y) {
	bne	4f	; 3	;  case 3 /* digits */ : // 000..199
	ldy	,s++	; 9	;   y = *((uint16_t*) &s[y]); // 1's for X
	ldb	,s+	; 7	;   b = s[y-1] << 1;      // 10's for b
	ror	,s+	; 9	;
	rolb		; 2	;   b |= s[y-2] & 0x01;   // 100's for c 
	bra	6f	; 3	;   break;
4	cmpy	#$0002	; 5	;
	bne	5f	; 3	;  case 2 /* digits */ : // 00..99
	ldy	,s++	; 9	;   y = *((uint16_t*) &s[y]); // 1's for X
	ldb	,s+	; 7	;   b = s[y-1] << 1;      // 10's for b
	aslb		; 2	;   b &= 0xfe;            // 100's is 0
	bra	6f	; 3	;   break;
5	cmpy	#$0001	; 5	;
	bne	8f	; 3	;  case 1 /* digit */ : // 0..9
	ldy	,s++	; 9	;   y = *((uint16_t*) &s[y]); // 1's for X
	clrb		; 2	;   b = 0;                // 10's, 100's are 0
6	stx	,--s	; 5	;  }
	tfr	y,x	; 6	;
	cmpa	#'-'	; 2	;
	beq	7f	; 3	;  int16_t d;
	lsrb		; 2	;               
	jsr	d8pstv	; 8 (33);  if (a != '-')
	bra	8f	; 3	;   d = d8pstv(b & 0x01, b >> 1, x); //100,10,1
7	lsrb		; 2	;  else
	jsr	d8ngtv	; 8 (49);   d = d8ngtv(b & 0x01, b >> 1, x);  //100,10,1
8	ldx	,s++	; 8	;
	rts		; 5	;  return d;
9	tfr	y,d	; ?	; } else
	leas	d,s	; 8	;
	ldd	#$8000	; ?     ;  return d = NaN;
	rts		; 5(343);} // get3bcd()

;;; convert a signed ASCII decimal integer -32767..32767 at X to binary in Y
get5bcd	ldy	#$0000	; 4	;int16_t get5bcd(const char** x, int16_t* y) {
	clra		; 2	; uint16_t y = 0, d;
0	jsr	peekdig	; 8 (48); uint8_t a = 0, b, s[5];
	leay	,y	;	;
	bne	1f	;	; do {
	bitb	#$40	;	;  b = peekdig(x, &a); // sign or 1st dig in A
	beq	1f	;	;
	cmpb	#'@'	;	;
	beq	1f	;	;
	ldb	#$01	;	;  if (y == 0 && b >= 'A') {
	stb	,-s	; 6	;   s[y++] = 1; // var with implicit 1 coeff
	leay	1,y	;	;
	bra	4f	; 3	;   break;
1	cmpb	#'0'	; 2	;
	blo	3f	; 3	;
	cmpb	#'9'	; 2	;
	bhi	3f	; 3	;  } else if (b >= '0' && b <= '9') {
	leax	1,x	; 5	;   (*x)++; // x points past verified digit
	leay	-5,y	; 5	;
	beq	2f	; 3	;   if (y != 5) // *x points to a known digit
	leay	6,y	; 5	;
	andb	#$0f	; 2	;
	stb	,-s	; 6	;    s[y++] = b - '0';
	bra	0b	; 3	;   else
2	clrb		; 2	;    b = 0; // indicates unsuccessful conversion
	tfr	y,d	; 6	;
	bra	6f	; 3	;  }
3	tstb		; 2	; } while (b);
	bne	4f	; 3	;
	tfr	y,d	; 6	;
	bra	6f	; 3	; if (b) {
4	cmpa	#'-'	; 2	;  if (a != '-')
	beq	5f	; 3	;   b = y, y = d16pstv(y, s); // x is preserved
	jsr	d16pstv	; 8(402);  else
	bra	6f	; 3	;   b = y, y = d16ngtv(y, s); // =-d16pstv(y,s);
5	jsr	d16ngtv	; 8(439); }
6	leas	d,s	; 8	; return b & 0x07; // d digits converted as y
	rts		; 5(945);} // get5bcd()

;;; divide a 16-bit signed quantity in X into a 16-bit signed quantity in D
x16divd	leas	-4,s	;	;int16_t x16divd(int16_t d, int16_t x) {
	stx	,s	;	; int16_t s[2]; // to detect crossing past zero
	beq	7f	;	; if ((s[0] = x) == 0)
	std	2,s	;	;  return 0x8000; // divisor 0, return NaN 
	beq 	8f	;	; if ((s[1] = d) == 0)
	ldx	#$0000	;	;  return 0; // quotient also 0, without calc'n
	eora	,s	;	;       // maintain sign // remember signs' xor
	sta	3,s	;	; s[1] = (0xff00 & s[1]) | ((d^x) >> 8);// in b7
	bpl	0f	;	; if (s[1] & 0x0080 /* d^x<0 */) // quotient < 0
	eora	,s	;	;
	coma		;	;
	comb		;	;
	addd	#$0001	;	;
	sta	2,s	;	;  s[1] = d = -d; // now x and d have same sign
	bra	1f	;	;
0	eora	,s	;	;
1	leax	1,x	;	; for (x = 1; s[0]; x++)
	subd	,s	;	;  if ((d -= s[0]) == 0)
	beq	3f	;	;   break; // divides exactly (no remainder)
	bpl	2f	;	;  else if (d < 0) {
	tst	2,s	;	;   if (s[1] > 0) 
	bmi	1b	;	;    break; // crossed 0 (positive to negative)
	bra	3f	;	;  } else if (d > 0)
2	tst	2,s	;	;   if (s[1] < 0)
	bpl	1b	;	;    break; // crossed 0 (negative to positive)
3	exg	x,d	;	; int16_t temp = x, /*R*/ x = d, d /*Q*/ = temp;
 if 0	
4	cmpx	,s	;	;
	bne	5f	;	;
	ldx	#$0000	;	;
 endif
5	cmpx	#$0000	;	;
	beq	6f	;	; if (x > 0) // nonzero remainder, subtract 1
	addd	#$ffff	;	;  d--; // from quotient rather than rounding up
6	tst	3,s	;	;
	bpl	8f	;	; if (s[1] & 0x0080)
	coma		;	;
	comb		;	;
	addd	#$0001	;	;  d = -d;
	bra	8f	;	;
7	ldd	#$8000	;	; // |remainder| = |divisor| + |x|
8	leas	4,s	;	; return d; // floor of quotient
	rts		;	;} // x16divd()

;;; multiply an 8-bit signed number in X by a 16-bit signed number in D
x8mul16	stx	,--s	;	;int16_t x8mul16(int8_t x, uint16_t d) {
	std	,--s	;	; // s+2: sign storage post-abs() s+3: copy of x
	eora	3,s	;	; // s+0: copy of d
	sta	2,s	;	; int8_t s/*ign of product*/ = (d>>8) ^ x;
	lda	3,s	;	; uint16_t product; // = (256a+b)x = 256ax+bx
	bpl	1f	;	; if (x < 0)
	nega		;	;
	sta	3,s	;	;  x = -x;
1	ldb	,s	;	;
	bpl	2f	;	; if (d < 0)
	com	,s	;	;
	com	1,s	;	;
	ldd	#$0001	;	;
	addd	,s	;	;
	std	,s	;	;  d = -d; // = 256a + b
	ldb	,s	;	;
2	mul		;	; product = x * ((d & 0xff00) >> 8);
	tsta		;	;
	bne	3f	;	; if (product <= 255) {
	stb	,s	;	;
	ldb	1,s	;	;
	clr	1,s	;	;  product <<= 8; // = 256ax
	lda	3,s	;	;
	mul		;	;
	addd	,s	;	;  product += x * (d & 0x00ff); // = 256ax + bx
	bvs	3f	;	;  if (product <= 32767)
	tst	2,s	;	;
	bpl	4f	;	;
	coma		;	;
	comb		;	;
	addd	#$0001	;	;
	bra	4f	;	;   return (s > 0) ? product : -product;
3	ldd	#$8000	;	; }	
4	leas	4,s	;	; return 0x8000; // NaN
	rts		;	;} // x8mul16()
	
;;; cube a 6-bit signed number sign-extended in X into D
	if SIZE_OVER_SPEED
x3sgnd6	 stx	,--s	; 8	;int16_t x3sgnd6(register int16_t x) {
	 ldd	,s	; 5	; int16_t s[2], d;
	 bpl	1f	; 3	; if ((s[1] = d = x) < 0) {
	 negb		; 2	;
	 sex		; 2	;
	 tfr	d,x	; 6	;
	 jsr	x3sgnd6	; 8(164);
	 coma		; 2	;
	 comb		; 2	;
	 addd	#$0001	; 4	;  return -x3sgnd6(x = -d);
	 bra	3f	; 3	; } else {
1	 neg	1,s	; 7	;  s[1] = 0x00ff & -d; // -d stored in low byte,
	 stb	,s	; 4	;  s[1]|= d<<8;// original d stored in high byte
	 bitb	#$40	; 2	;
	 beq	2f	; 3	;  if (x >= 32) // would overflow an int16_t, so
	 ldd	#$8000	; 3	;   return d = 0x8000; // return a NaN
	 bra	3f	; 3	;
2	 andb	#$1e	; 2	;  else { // square of largest even integer <= d
	 tfr	b,a	; 6	;   d = (d & 1) ? d-1 : d; // fits in bits 9..2
	 mul		; 11	;   d *= d; // using the algebraic identity:
	 std	,--s	; 8	;           // x(x-1)^2 = x^3 - 2x^2 + x
	 asl	1,s	; 7	;
	 rol	,s	; 6	;   s[0] = d<<1; // shift to bits 10..3 as 2*x^2
	 asra		; 2	;
	 rorb		; 2	;  
	 asra		; 2	;  
	 rorb		; 2	;   d >>= 2; // shift into bits 7..0 for cube
	 lda	2,s	; 5	;
	 mul		; 11	;   d *= s[1]>>8; // stored copy of x
	 aslb		; 2	;
	 rola		; 2	;
	 aslb		; 2	;
	 rola		; 2	;   d <<= 2; // then restore the cube bits 15..0
	 ror	2,s	; 7	;
	 bcc	4f	; 3	;   if (s[1] & 0x0100) { // was odd, so +2*x^2-x
	 addd	,s++	; 9	;    d += s[0]; // 2*x^2
	 clr	2,s	; 7	;
	 dec	2,s	; 7	;    d += 0x00ff & s[1]; // -x
	 addd	2,s	; 7	;   }
3	 leas	2,s	; 5	;   return d;
	 rts		; 5(209);  }
4	 leas	4,s	; 5	; }
	 rts		; 5(209);}
	elsif SPEED_OVER_SIZE
;;; optimized for speed (and constant speed at that) using a lookup table:
;	 fdb	$8000		;int16_t x3sgnd6(register int8_t x) {
	 fdb	$0000		; int16_t NaN = 0x8000, lut[32] = { 0,    // 0^3
	 fdb	$0001		;                                   1,    // 1^3
	 fdb	$0008		;                                   8,    // 2^3
	 fdb	$001b		;                                   27,   // 3^3
	 fdb	$0040		;                                   64,   // 4^3
	 fdb	$007d		;                                   125,  // 5^3
	 fdb	$00d8		;                                   216,  // 6^3
	 fdb	$0157		;                                   343,  // 7^3
	 fdb	$0200		;                                   512,  // 8^3
	 fdb	$2d9		;                                   729,  // 9^3
	 fdb	$03e8		;                                   1000, //10^3
	 fdb	$0533		;                                   1331, //11^3
	 fdb	$06c0		;                                   1728, //12^3
	 fdb	$0895		;                                   2197, //13^3
	 fdb	$0ab8		;                                   2744, //14^3
	 fdb	$0d2f		;                                   3375, //15^3
	 fdb	$1000		;                                   4096, //16^3
	 fdb	$1331		;                                   4913, //17^3
	 fdb	$16c8		;                                   5832, //18^3
	 fdb	$1acb		;                                   6859, //19^3
	 fdb	$1f40		;                                   8000, //20^3
	 fdb	$242d		;                                   9261, //21^3
	 fdb	$2998		;                                   10648,//22^3
	 fdb	$2f87		;                                   12167,//23^3
	 fdb	$3600		;                                   13824,//24^3
	 fdb	$3d09		;                                   15625,//25^3
	 fdb	$44a8		;                                   17576,//26^3
	 fdb	$4ce3		;                                   19683,//27^3
	 fdb	$55c0		;                                   21952,//28^3
	 fdb	$5f45		;                                   24389,//29^3
	 fdb	$6978		;                                   27000,//30^3
	 fdb	$745f		;                                   29791 //31^3
x3sgnd6	 tfr	x,d	; 6	;                                 };
	 bitb	#$60	; 2	; register int16_t d = (int16_t)x;
	 bmi	2f	; 3	; if (((d & 0xff80) && !(d & 0x0060))
	 bne	3f	; 3	;     ||
1	 ldd	#$8000	; 3	;     (!(d & 0xff80) && (d & 0x0060)))
	 rts		; 5	;  return d = NaN;
2	 beq	1b	; 3	; else if (d < 0)
	 negb		; 2	;
	 jsr	3f	; 8(31)	;
	 coma		; 2	;
	 comb		; 2	;
	 addd	#$0001	; 4	;
	 rts		; 5(60)	;  return d = -x3sgnd6(-d);// odd so f(-x)=-f(x)
3	 lda	#$ff	; 2	;
	 aslb		; 2	;
	 orb	#$c0	; 2	;
	 ldx	#x3sgnd6; 3	; else
	 ldd	d,x	; 9	;  return d = lut[d & 0x001f];
	 rts		; 5(37)	;} // x3sgnd6()
	endif

;;; read a polynomial with int16_t coefficients, variables and uint2_t exponents
getpoly	cmpx	10,s	;	;int8_t getpoly(register char* x, int16_t s[5]){
	bhi	5f	;	; while (x <= (char*)(s[5])) { // not at end yet
	jsr	get5bcd	; 	;  int16_t y, d = get5bcd(&x, &y); // past digit
	tstb		;	;
	beq	4f	;	;  if (d) { // successfully converted into Y
	lda	,x+	;	;   char a = *x++; // expecting var, +, - or end
	cmpa	#'@'	;	;
	bne	1f	;	;   if (a == '@') {// comma before initial guess
	jsr	get5bcd	;	;    uint8_t b = get5bcd(&x, &y);
	tstb		;	;    if (b == 0)
	beq	4f	;	;     return -1;// no value provided after comma
	bra	5f	;	;    break; // initial guess (or junk) is in y
1	deca		;	;
	anda	#$40	;	;   } else if (a >= 'A') { // letter, maybe exp
	beq	2f	;	;
	ldb	,x+	;	;    char b = *x++;  // expecting 0,1,2,3,+ or -
	cmpb	#'0'	;	;
	blo	4f	;	;    if (b < '0')
	cmpb	#'4'	;	;     return -1;// invalid character encountered
	blo	3f	;	;    else if (b >= '4')
	ldb	#'1'	;	;     b = '1'; // implied exponent of 1
2	leax	-1,x	;	;    else
3	clra		;	;     ++x; // ate the exponent, so undo our --x:
	aslb		;	;   } // we now have coefficient in y, exp in b
	andb	#$06	;	;   --x; // back up to get potential next term
	addb	#$02	;	;
	sts	,--s	;	;
	addd	,s++	;	;
	exg	d,y	; 8	;
	addd	,y	;	;
	std	,y	;	;   s[b - '0'] += y;
	bra	getpoly	;	;   continue;
4	lda	#$ff	;	;
	ldb	#$ff	;	;  } else
	rts		;	;   return -1;// conversion failed
5	tfr	y,x	; 6	;
	clra		;	;
	ldb	4,s	;	; }
	orb	5,s	;	; 
	orb	6,s	;	; x = y; // initial guess (or junk) is in x
	orb	7,s	;	; // (doesn't matter, used only for convergence)
	orb	8,s	;	;
	orb	9,s	;	; return s[1] | s[2] | s[3];// 0 if no var found
	rts		;	;} // getpoly()

ifisNaN	macro
	aslb		;	;inline uint8_t ifisNaN(int16_t d, void(*f)()) {
	bne	2f	;	;
	rola		;	;
	bne	1f	;	;
	bcc	1f	;	;
	bra	\1	;	; if (d == 0x8000)
1	rora		;	;  (*f)(); // actually a goto
2	rorb		;	;} // ifisNaN()
	endm
	
o3eval	stx	,--s	;	;int16_t o3eval(int16_t x, int16_t s[4]) {
	ldd	,s	;	; int16_t sum;
	tsta		;	; register union { int16_t d; int8_t a, b; } d;
	beq	2f	;	; // s+0: value // s+2: |x| // s+3: x // s+4: PC
	inc	,s	;	; // s+6: a0 // s+8: a1 // s+10: a2 // s+12: a3
	bne	1f	;	;
	tstb		;	;
	bpl	1f	;	;
	negb		;	; if (x < -127 || x > 255)
	bra	2f	;	;  x = (0x00ff & x); // can't store |x| in upper
1	ldb	#0x00	;	; else
2	stb	,s	;	;  x = (0x00ff & x) | (((x > 0) ? x : -x) << 8);
	ldd	4,s	;	;
	std	,--s	;	; sum = s[0]; // = a0
	
	ldd	8,s	;	; if (s[1]) {
	beq	3f	;	;
	jsr	x8mul16	;	;  d.d = (x & 0xff) * s[1];
	ifisNaN	10f	;	;  if (d.d < -32767 || d.d > 32767) goto overf;
	addd	,s	;	;  d.d += sum;
	bvs	10f	;	;  if (d.d < -32767 || d.d > 32767) goto overf;
	std	,s	;	;  sum = d.d; // = a0 + a1 x

3	ldd	10,s	;	; }
	beq	9f	;	; if (s[2]) {
	lda	2,s	;	;
	ldb	2,s	;	;  d.a = d.b = (uint8_t)((x>0) ? x : -x); // |x|
	mul		;	;  d.d = d.a * d.b;
	bne	4f	;	;
	tst	3,s	;	;  if (x < -127 || x > 255)
	bne	10f	;	;   goto overf;
4	tsta		;	;
	bne	5f	;	;  if (d.d > 255 &&
	tfr	d,x	;	;
	ldd	10,s	;	;
	bra	8f	;	;
5	tst	10,s	;	;
	beq	7f	;	;     s[2] > 255)
	bra	10f	;	;   goto overf; // FIXME can't fit for now until
7	ldx	10,s	;	;  else // using (256*a+b)x=256*a*x+b*x identity
8	jsr	x8mul16	;	;   d.d *= s[2];
	ifisNaN	10f	;	;  if (d.d < -32767 || d.d > 32767) goto overf;
	addd	,s	;	;  d.d += sum;
	bvs	10f	;	;  if (d.d < -32767 || d.d > 32767) goto overf;	
	std	,s	;	;  sum = d.d; // = a0 + a1 x + a2 x^2

9	ldd	12,s	;	; }
	beq	11f	;	; if (s[3]) {
	ldx	2,s	;	;
	jsr	x3sgnd6	;	;  d.d = x * x * x;
	ifisNaN	10f	;	;  if (d.d < -32767 || d.d > 32767) goto overf;
	ldx	12,s	;	;
	jsr	x8mul16	;	;
	ifisNaN	10f	;	;  if (d.d < -32767 || d.d > 32767) goto overf;
	addd	,s	;	;  d.d += sum;
	bvs	10f	;	;  if (d.d < -32767 || d.d > 32767) goto overf;	
	std	,s	;	;  sum = d.d; // = a0 + a1 x + a2 x^2 + a3 x^3
	bra	11f	;	; }
10	ldd	#$8000	;	; return d.d;
	std	,s	;	;
11	ldd	,s	;	; overf: return 0x8000; // NaN
	leas	4,s	;	;
	rts		;	;} // o3eval()

;;; compute the first derivative of the cubic polynomial evaluated at X
o3drv1x	ldd	#$0000	;	;int16_t o3drv1x(int16_t x, int16_t s[4]) {
	std	,--s	;	; int16_t s1[4];
	if SPEED_OVER_SIZE
	 ldd	8,s	;	;
	 std	,--s	;	;
	 ldd	8,s	;	;
	 std	,--s	;	;
	 ldd	8,s	;	;
	 std	,--s	;	;
	elsif SIZE_OVER_SPEED
	 inca		;	;
0	 ldd	8,s	;	;
	 std	,--s	;	;
	 inca		;	;
	 bita	#$04	;	;
	 beq	0b	;	;
	endif
	ldd	4,s	;	; s1[3] = 0; // no cubic in derivative of same
	aslb		;	;
	rola		;	; s1[2] = 3 * s[3]; // a3 x^3 -> 3 a3 x^2
	addd	4,s	;	;
	std	4,s	;	; s1[1] = 2 * s[2]; // a2 x^2 -> 2 a2 x
	asl	3,s	;	;
	rol	2,s	;	; s1[0] = 1 * s[1]; // a1 x   ->   a1
	jsr	o3eval	;	; return d = o3eval(x, s1);
	leas	8,s	;	;} // o3drv1x()


;;; solve cubic equations (for int16_t solutions) using Newton-Raphson method
o3solve	jsr	eatspc	;8(6185);int16_t o3solve(struct {uint8_t n; char* c;}*x)
	stx	,--s	; 9	;{
	clra		; 2	; uint16_t s[6]; // stack args to/from getpoly()
	ldb	[,s]	;	; eatspc(x); // spaces compressed out of string
	addd	,s	;	; // stop point for scan at stack pointer + 8:
	std	,s	; 	; s[4] = x + x->n; // ECB string end at ptr+*ptr
	leas	-12,s	; 	;
	clr	7,s	; 7	; s[3] = 0; // x^3 coeff at stack pointer + 6
	clr	6,s	; 7	;
	clr	5,s	; 7	; s[2] = 0; // x^2 coeff at stack pointer + 4
	clr	4,s	; 7	;
	clr	3,s	; 7	; s[1] = 0; // x^1 coeff at stack pointer + 2
	clr	2,s	; 7	;
	clr	1,s	; 7	; s[0] = 0; // x^0 coeff at stack pointer + 0
	clr	,s	; 6	; // advance past size byte to string start:
	leax	1,x	; 5	; union {char* c, int16_t i}* x = 1 + (void*)x;
	jsr	getpoly	;5()    ; int16_t slope, d = getpoly(&x, s);
	tstb		;	;
	bne	1f	;	; if (!d) { // no vars encountered
	dec	2,s	;	;
	dec	3,s	;	;  s[1] = -1; // calculator mode
	ldx	,s	;	;  x.i = s[0]; // initial guess x will be exact
	bra	4f	;	;
1	tsta		;	;
	bpl	3f	;	; } else if (d < 0)
2	ldd	#$8000	;	;  return 0x8000; // NaN
	bra	5f	;	;
3	ldx	#$0000	;	; x = 0; // initial guess
	ldy	#$0003	;	; for (int16_t y = 3; y && d=o3eval(x, s); y--)
4	stx	10,s	;	;  // X temporarily held as s[5]
	jsr	o3eval	;	;
	ldx	10,s	;	;
	cmpd	#$0000	;	;
	beq	5f	;	;
	std	8,s	;	;  // o3eval() temporarily held as s[4]
	jsr	o3drv1x	;	;
	tfr	d,x	;	;
	ldd	8,s	;	;
	jsr	x16divd	;	;
	subd	10,s	;	;
	tfr	d,x	;	;  x -= d / o3drv1x(x);// Newton-Raphson formula
	leay	-1,y	;	;  // FIXME: double-check y isn't used in funcs!
	bne	4b	;	;
5	leas	14,s	;	; return d = x;
	rts		;	;}

