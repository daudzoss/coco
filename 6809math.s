;;; convert a 3-digit unsigned BCD 0..199 to binary unsigned in X
d0to199	lda	#$0a	; 2	;uint16_t d0to199(uint1_t c,  // 100's
	bcc	1f	; 3	;                 uint8_t b,   // 10's
	addb	#$0a	; 2	;                 uint16_t x) { // 1's
1	mul		;11	; uint16_t d = 10*(c*10 + b); c = d & 0x80;
	abx		; 2	; return x += d & 0xff; // = c*100 + b*10;
	rts		; 5 (25);} // d0to199()

;;; convert a 3-digit signed BCD -128..127 to binary unsigned in X, signed in D
d8sgnd	bmi	d8ngtv	; 3	;int16_t d8sgnd(uint1_t n, // sign
	jsr	d0to199	; 8 (33);               uint1_t c,  // 100's
	tfr	x,d	; 6	;               uint16_t d,  // 10's
	rts		; 2	;               uint16_t x) { // 1's
d8ngtv	jsr	d0to199	; 8 (33); return n ? d8ngtv(c, d, x) : d0to199(c, d, x);
	tfr	x,d	; 6	;} // d8sgnd()
	negb		; 2	;int16_t d8ngtv(uint1_t c,uint16_t d,uint16_t x)
	sex		; 2	;{return d = -(x += c*100 + d*10);
1	rts		; 5 (50);} // d8ngtv()

;;; multiply X -3276..3276 by 10 into D, e.g. to allow 5-digit BCD construction
x10ind	stx	,--s	; 5	;int16_t x10inD(int16_t x) {
	asl	,s	; 6	;
	ldd	,s	; 5	; uint16_t d = x*2;
	aslb		; 2	;
	rola		; 2	;
	aslb		; 2	;
	rola		; 2	;
	addd	,s++	; 9	; return d += d*4; // = x*10;
	rts		; 5 (38);} // x10inD()

;;; copy Y to D, convert a Y-digit unsigned BCD 0..32767 to binary unsigned in Y
d0to32k	stx	,--s	; 9	;uint16_t d0to32k(uint3_t y,
	ldx	#$0000	; 3	;                 const uint8_t* s) {
	sty	,--s	; 9	; uint16_t x, d = y; // digit count y <= 5
	beq	3f	; 3	;
	bne	2f	; 3	;
1	jsr	x10ind	; 8 (46); for (x = 0x0000; y; y--) {
2	leax	5,s	; 5 	;  // d is now x*10, x is now the digit pointer
	exg	d,x	; 8	;  x *= 10; // d is now the digit pointer
	ldb	d,y	; 8	;  uint8_t b = s[ /* 5[sic] + */ y]; // Y',X',PC
	abx		; 3	;  x += b;
	leay	-1,y	; 5	; }
	bne	1b	; 3	; // caller can pop d args with: leas d,s
3	tfr	x,y	; 6	;
	ldd	,s++	; 8	; return d, y = x;
	ldx	,s++	; 8	;
	rts		; 5(388);} // d0to32k()

;;; copy Y to D,convert a Y-digit signed BCD -32767..32767 to binary signed in Y
d16sgnd	bmi	d16ngtv	; 3	;int16_t d16sgnd(uint1_t n,
	jsr	d0to32k	; 8(402);                uint3_t y,
	rts		; 2	;                uint8_t* s) {
d16ngtv	jsr	d0to32k	; 8(402); uint16_t x, d = y; // digit count y <= 5
	exg	x,d	; 8	; return d, x = n ? d16ngtv(y,s) : d0to32k(y,s);
	coma		; 2	;} // d16sgnd()
	comb		; 2	;int16_t d16ngtv(uint3_t y, uint8_t* s) {
	addd	#$0001	; 4	; uint16_t x, d = y; // digit count y <= 5
	exg	x,d	; 8	; return d, x = -d0to32k(y, s);
	rts		; 5(444);} // d16ngtv()

;;; look ahead to next character in the array, plus one more if it's a +/- sign
peekdig	ldb	,x	; 2	;char peekdig(const char** x, char* a/*zero*/) {
	cmpb	#'-'	; 2	; char b = *(*x);
	bne	2f	; 3	;
	tsta		; 2	; if (b == '-' || b == '+') {
	bne	4f	; 3	;  if (*a == '\0') { // first character found
1	lda	,x+	; 4	;   *a = b; // gets stored in *a to remember '-'
	ldb	,x	; 2	;   b = ++(*x); // then advance *x pointer once
	cmpb	#'0'	; 2	;
	blo	3f	; 3	;
	cmpb	#'9'	; 2	;
	bhi	3f	; 3	;   
	rts		; 2	;
2	cmpb	#'+'	; 2	;   // but if the next character after a sign
	bne	4f	; 3	;   // isn't a digit or letter i.e. a variable
	tsta		; 2	;   // with coeff 1, there is an error condition
	beq	1b	; 3	;   if (b < '0' || b > '9')
	bne	4f	; 3	;    b = (b & 0xc0) ? /*implicit*/ 1 : 0/*err*/;
3	andb	#$c0	; 2	;  }
	beq	4f	; 3	; }
	ldb	#$01	; 2	; return b;
4	rts		; 5 (40);} // peekdig()

;;; convert a signed ASCII decimal integer -127..127 at X to binary in Y
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
	cmpa	#'-'	; 2	;  uint16_t x = y; // local preserves pointer X
	beq	7f	; 3	;  int16_t d;
	lsrb		; 2	;               
	jsr	d0to199	; 8 (33);  if (a != '-')
	bra	8f	; 3	;   d = d0to199(b & 0x01, b >> 1, x); //100,10,1
7	lsrb		; 2	;  else
	jsr	d8ngtv	; 8 (49);   d = d8ngtv(b & 0x01, b >> 1, x);  //100,10,1
8	tfr	y,d	; 6	;  d = y; // d total digits converted
	tfr	x,y	; 6	;  y = x; // y result of conversion
	ldx	,s++	; 8	; }
9	leas	d,s	; 8	; return d & 0x03;
	rts		; 5(343);} // get3bcd()

;;; convert a signed ASCII decimal integer -32767..32767 at X to binary in Y
get5bcd	ldy	#$0000	; 4	;int16_t get5bcd(const char** x, int16_t* y) {
	clra		; 2	; uint16_t y = 0, d;
1	jsr	peekdig	; 8 (48); uint8_t a = 0, b, s[5];
	cmpb	#'0'	; 2	;
	blo	3f	; 3	; do {
	cmpb	#'9'	; 2	;  b = peekdig(x, &a); // sign or 1st dig in a
	bhi	3f	; 3	;  if (b >= '0' && b <= '9') { // verified digit
	leax	1,x	; 5	;   (*x)++;
	leay	-5,y	; 5	;
	beq	2f	; 3	;   if (y != 5) // *x points to a known digit
	leay	6,y	; 5	;
	andb	#$0f	; 2	;
	stb	,-s	; 6	;    s[y++] = b - '0';
	bra	1b	; 3	;   else
2	clrb		; 2	;    b = 0; // indicates unsuccessful conversion
	tfr	y,d	; 6	;
	bra	6f	; 3	;  }
3	tstb		; 2	; } while (b);
	bne	4f	; 3	;
	tfr	y,d	; 6	;
	bra	6f	; 3	; if (b) {
4	cmpa	#'-'	; 2	;  if (a != '-')
	beq	5f	; 3	;   b = y, y = d0to32k(y, s); // x is preserved
	jsr	d0to32k	; 8(402);  else
	bra	6f	; 3	;   b = y, y = d16ngtv(y, s); // =-d0to32k(y,s);
5	jsr	d16ngtv	; 8(439); }
6	leas	d,s	; 8	; return b & 0x07; // d digits converted as y
	rts		; 5(945);} // get5bcd()

;;; cube an 8-bit signed number in low X byte into D, optimizing to fit into 16b
x3sgnd8	stx	,--s	;	;int16_t x3sgnd8(register int8_t x) {
	ldd	,s	;	; int16_t s[2], d = x;
	neg	1,s	;	; s[1] = 0x00ff & -x; // -x stored in low byte,
	stb	,s	;	; s[1] |= d<<8;// original x stored in high byte
	bpl	1f	;	; if (x < 0) {
	negb		;	;  d = 0x00ff & -d; // d >= 0, 0x00ff&s[1] >= 0
	jsr	2f	;	;
	coma		;	;
	comb		;	;
	addd	#$0001	;	;  return -d;
	bra	stackpop;	; } else { 
1	nop		;	;
2	bitb	#$e0	;	;
	beq	3f	;	;  if (x >= 32) // would overflow an int16_t, so
	ldd	#$8000	;	;   return d = 0x8000; // return a NaN
	bra	stackpop;	;
3	andb	#$1e	;	;  else { // square of largest even integer <=d,
	lda	,s	;	;         // as mult of 4, fits in 8 bits d9..d2
	mul		;	;   d = (d & 1 ? d-1 : d) * (d & 1 ? d-1 : d);
	std	,--s	;	;
	asl	1,s	;	;
	rol	,s	;	;   s[0] = d<<1; // shift to bits 10..3 as 2*x^2
	asra		;	;
	rorb		;	;  
	asra		;	;  
	rorb		;	;   d >>= 2; // shift into d7..d0 to prepare for
	lda	2,s	;	;
	mul		;	;   d *= (s[1]>>8) & 1 ? (s[1]>>8)-1 : s[1]>>8;
	aslb		;	;
	rola		;	;
	aslb		;	;
	rola		;	;   d <<= 2; // then restore the cube as d15..d0
	




	tfr	d,x	;	;
	ldd	,s	;	;
	andb	#1	;	;  if (x & 1) // if x really is even, we're done
	beq	stackpop;	;   return d;











	
stackpopleas	2,s
	tfr	x,d		;
	rts
	
;;; optimized for speed (and constant time) using a lookup table:
;	fdb	$8000		;int16_t x3sgnd8(register int8_t x) {
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
x3sgnd8	tfr	x,d	; 6	;                                 };
	bitb	#$60	; 2	; register int16_t d = (int16_t)x;
	bmi	2f	; 3	; if (((d & 0xff80) && !(d & 0x0060))
	bne	3f	; 3	;     ||
1	ldd	#$8000	; 3	;     (!(d & 0xff80) && (d & 0x0060)))
	rts		; 5	;  return d = NaN;
2	beq	1b	; 3	; else if (d < 0)
	negb		; 2	;
	jsr	3f	; 8(31)	;
	comb		; 2	;
	coma		; 2	;
	addd	#$0001	; 4	;
	rts		; 5(60)	;  return d = -x3sgnd8(-d);// odd so f(-x)=-f(x)
3	lda	#$ff	; 2	;
	aslb		; 2	;
	orb	#$c0	; 2	;
	ldx	#x3sgnd8; 3	; else
	ldd	d,x	; 9	;  return d = lut[d & 0x001f];
	rts		; 5(37)	;} // x3sgnd8()
	
;;; solve cubic equations (for int16_t solutions) using Newton-Raphson method
o3solve	jsr	eatspc	;8(6433);int16_t o3solve(struct {uint8_t n; char* c;}* x)
	stx	,--s	; 9	;{
	clra		; 2	; uint16_t s[5]; // stack args to/from getpoly()
	ldb	[,s]	;	; eatspc(x); // spaces compressed out of string
	addd	,s	;	; // stop point for scan at stack pointer + 8:
	std	,s	; 	; s[4] = x + x->n; // ECB string end at ptr+*ptr
	leas	-8,s	; 	;
	clr	7,s	; 7	; s[3] = 0; // x^3 coeff at stack pointer + 6
	clr	6,s	; 7	;
	clr	5,s	; 7	; s[2] = 0; // x^2 coeff at stack pointer + 4
	clr	4,s	; 7	;
	clr	3,s	; 7	; s[1] = 0; // x^1 coeff at stack pointer + 2
	clr	2,s	; 7	;
	clr	1,s	; 7	; s[0] = 0; // x^0 coeff at stack pointer + 0
	clr	,s	; 6	; // advance past size byte to string start:
	leax	1,x	; 5	; union {char* c, int16_t i} x = x++;
	jsr	getpoly	;5()    ; uint16_t d = getpoly(&x, s);
	tstb		;	;
	bne	1f	;	; if (!d) { // no vars encountered
	dec	2,s	;	;
	dec	3,s	;	;  s[1] = -1; // calculator mode
	ldx	,s	;	;  x.i = s[0]; // initial guess x will be exact
	bra	2f	;	;
1	tsta		;	;
	bpl	2f	;	; } else if (d < 0) {
error	
2	
	
