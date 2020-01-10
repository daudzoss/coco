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
	tfr	x,d	; 7	;               uint16_t d,  // 10's
	rts		; 2	;               uint16_t x) { // 1's
d8ngtv	jsr	d0to199	; 8 (33); return n ? d8ngtv(c, d, x) : d0to199(c, d, x);
	tfr	x,d	; 7	;} // d8sgnd()
	negb		; 2	;int16_t d8ngtv(uint1_t c,uint16_t d,uint16_t x)
	sex		; 2	;{return d = -(x += c*100 + d*10);
1	rts		; 5 (52);} // d8ngtv()

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
	sty	,--s	; 9	;                 const uint8_t* s) {
	ldx	#$0000	; 3	; uint16_t x, d = y; // digit count y <= 5
	beq	2f	; 3	;
1	jsr	x10ind	; 8 (46); for (x = 0x0000; y; y--) {
	leax	5,s	; 5 	;  // d is now x*10, x is now the digit pointer
	exg	d,x	; 7	;  x *= 10; // d is now the digit pointer
	ldb	d,y	; 8	;  uint8_t b = s[ /* 5[sic] + */ y]; // Y',X',PC
	abx		; 3	;  x += b;
	leay	-1,y	; 5	; }
	bne	1b	; 3	; // caller can pop d args with: leas d,s
2	tfr	x,y	; 7	;
	ldd	,s++	; 8	; return d, y = x;
	ldx	,s++	; 8	;
	rts		; 5(437);} // d0to32k()

;;; copy Y to D,convert a Y-digit signed BCD -32767..32767 to binary signed in Y
d16sgnd	bmi	d16ngtv	; 3	;int16_t d16sgnd(uint1_t n,
	jsr	d0to32k	; 8(445);                uint3_t y,
	rts		; 2	;                uint8_t* s) {
d16ngtv	jsr	d0to32k	; 8(445); uint16_t x, d = y; // digit count y <= 5
	exg	x,d	; 7	; return d, x = n ? d16ngtv(y,s) : d0to32k(y,s);
	coma		; 2	;} // d16sgnd()
	comb		; 2	;int16_t d16ngtv(uint3_t y, uint8_t* s) {
	addd	#$0001	; 4	; uint16_t x, d = y; // digit count y <= 5
	exg	x,d	; 7	; return d, x = -d0to32k(y, s);
	rts		; 5(475);} // d16ngtv()

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
get3bcd	ldy	#$0000	; 4	;int16_t get3bcd(const char** x) {
	clra		; 2	; uint16_t y = 0, d;
1	jsr	peekdig	; 8 (48); uint8_t a = 0, b, s[4];
	cmpb	#'0'	; 2	;
	blo	3f	; 3	; do {
	cmpb	#'9'	; 2	;  b = peekdig(x, &a);
	bhi	3f	; 3	;  if (b >= '0' && b <= '9') { // verified digit
	leax	1,x	; 5	;   (*x)++;
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
	ldb	,s	; 4	;  s[y+1] = s[y];  // convert s[y] from uint8_t
	clr	,s	; 6	;  s[y] = 0x00; // to uint16_t in order to pop y
	stb	,--s	; 5	;  switch (y) {
	cmpy	#$0003	; 5	;
	bne	4f	; 3	;  case 3 /* digits */ : // 000..199
	ldy	,s++	; 9	;   y = (uint16_t) &s[y]; // 1's for X
	ldb	,s+	; 7	;   b = s[y-1] << 1;      // 10's for b
	ror	,s+	; 9	;
	rolb		; 2	;   b |= s[y-2] & 0x01;   // 100's for c 
	bra	6f	; 3	;   break;
4	cmpy	#$0002	; 5	;
	bne	5f	; 3	;  case 2 /* digits */ : // 00..99
	ldy	,s++	; 9	;   y = (uint16_t) &s[y]; // 1's for X
	ldb	,s+	; 7	;   b = s[y-1] << 1;      // 10's for b
	aslb		; 2	;   b &= 0xfe;            // 100's is 0
	bra	6f	; 3	;   break;
5	cmpy	#$0001	; 5	;
	bne	8f	; 3	;  case 1 /* digit */ : // 0..9
	ldy	,s++	; 9	;   y = (uint16_t) &s[y]; // 1's for X
	clrb		; 2	;   b = 0;                // 10's, 100's are 0
6	stx	,--s	; 5	;  }
	tfr	y,x	; 7	;
	cmpa	#'-'	; 2	;  uint16_t x = y; // local preserves pointer X
	beq	7f	; 3	;  int16_t d;
	lsrb		; 2	;               
	jsr	d0to199	; 8();  if (a != '-')
	tfr	x,d	; 7	;   d = d0to199(b & 0x01, b >> 1, x); //100,10,1
	bra	8f	; 3	;  else
7	lsrb		; 2	;
	jsr	d8ngtv	; 8();   d = d8ngtv(b & 0x01, b >> 1, x);  /100,10,1
8	exg	d,y	; 7	;  x = d, d = y, y = x; // d digits converted
	ldx	,s++	; 8	; }
9	leas	d,s	; 8	; return d & 0x07, y; // result in y
	rts		; 5();} // get3bcd()

;;; convert a signed ASCII decimal integer -32767..32767 at X to binary in Y
get5bcd	ldy	#$0000	; 4	;int16_t get5bcd(const char** x) {
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
	tfr	y,d	; 7	;
	bra	6f	; 3	;  }
3	tstb		; 2	; } while (b);
	bne	4f	; 3	;
	tfr	y,d	; 7	;
	bra	6f	; 3	; if (b) {
4	cmpa	#'-'	; 2	;  if (a != '-')
	beq	5f	; 3	;   b = y, y = d0to32k(y, s); // x is preserved
	jsr	d0to32k	; 8(445);  else
	bra	6f	; 3	;   b = y, y = d16ngtv(y, s); // =-d0to32k(y,s);
5	jsr	d16ngtv	; 8(472); }
6	leas	d,s	; 8	; return b & 0x07, y; // d digits converted as y
	rts		; 5(994);} // get5bcd()
	
