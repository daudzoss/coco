;;; convert a 3-digit unsigned BCD 0..199 to binary unsigned in X
d0to199	lda	#$0a	; 2	;uint16_t d0to199(uint1_t c,  // 100's
	bcc	1f	; 3	;                 uint8_t b,   // 10's
	addb	#$0a	; 2	;                 uint16_t x) { // 1's
1	mul		;11	; uint16_t d = 10*(c*10 + b); c = d & 0x80;
	abx		; 2	; return x += d & 0xff; // = c*100 + b*10;
	rts		; 2 (22);} // d0to199()

;;; convert a 3-digit signed BCD -128..127 to binary unsigned in X, signed in D
d8sgnd	jsr	d0to199	; 8 (30);int16_t d8sgnd(uint1_t n, // sign
	tfr	x,d	; 7	;               uint1_t c,  // 100's
	bpl	1f	; 3	;               uint16_t d,  // 10's
	negb		; 2	;               uint16_t x) { // 1's
	sex		; 2	; return d = (x += c*100 + b*10) * (n ? -1 : 1);
1	rts		; 2 (46);} // d8sgned()

;;; multiply X -3276..3276 by 10 into D, e.g. to allow 5-digit BCD construction
x10ind	stx	,--s	; 5	;int16_t x10inD(int16_t x) {
	asl	,s	; 6	;
	ldd	,s	; 5	; uint16_t d = x*2;
	aslb		; 2	;
	rola		; 2	;
	aslb		; 2	;
	rola		; 2	;
	addd	,s++	; 9	; return d += d*4; // = x*10;
	rts		; 2 (35);} // x10inD()

;;; copy Y to D, convert a Y-digit unsigned BCD 0..32767 to binary unsigned in Y
d0to32k	stx	,--s	;	;uint16_t d0to32k(uint3_t y,
	sty	,--s	; 9	;                 const uint8_t* s) {
	ldx	#$0000	; 3	; uint16_t x, d = y; // digit count y <= 5
	beq	2f	; 3	;
1	jsr	x10ind	; 8 (43); for (x = 0x0000; y; y--) {
	leax	5,s	; 5 	;  // d is now x*10, x is now the digit pointer
	exg	d,x	; 7	;  x *= 10; // d is now the digit pointer
	ldb	d,y	; 8	;  uint8_t b = s[ /* 5[sic] + */ y]; // Y',X',PC
	abx		; 3	;  x += b;
	leay	-1,y	; 5	; }
	bne	1b	; 3	; // caller can pop d args with: leas d,s
2	tfr	x,y	;	;
	ldd	,s++	; 8	; return d, y = x;
	ldx	,s++	;	;
	rts		; 2(395);} // d0to32k()

;;; copy Y to D,convert a Y-digit signed BCD -32767..32767 to binary signed in Y
d16sgnd	bmi	d16ngtv	; 3	;int16_t d16sgnd(uint1_t n,
	jsr	d0to32k	; 8(403);                uint3_t y,
	rts		; 2	;                uint8_t* s) {
d16ngtv	jsr	d0to32k	; 8(403); uint16_t x, d = y; // digit count y <= 5
	exg	x,d	; 7	;
	coma		; 2	;
	comb		; 2	; // 
	addd	#$0001	; 4	; // caller can pop d args with: leas d,s
	exg	x,d	; 7	; return d, x = d0to32k(y, s) * (n ? -1 : 1);
	rts		; 2(430);} // d16sgnd()

;;; look ahead to next character in the array, plus one more if its the sign
1	lda	,x		;
	ldb	,+x		;
	cmpb	#'0'		;
	blo	3f		;
	cmpb	#'0'		;
	bhi	3f		;
;	rts
peekdig	ldb	,x		;char peekdig(const char** x, char* a/*zero*/) {
	cmpb	#'-'		; char b = *(*x);
	bne	2f		;
	tsta			; if (b == '-' || b == '+') {
	beq	1b		;  if (*a == '\0') { // first character found
	bne	4f		;   *a = b; // gets stored in *a to remember '-'
2	cmpb	#'+'		;   ++(*x); // then advance x pointer past it
	bne	4f		;   if (*(*x) >= '0' && *(*x) <= '9')
	tsta			;    b = peekdig(x, a); // = *(*x);
	beq	1b		;   else
	bne	4f		;    b = (b & 0xc0) ? /*implicit*/ 1 : 0/*err*/;
3	andb	#$c0		;  }
	beq	4f		; }
	ldb	#$01		; return b;
4	rts			;}
	
get5bcd	ldy	#$0000		;int16_t get5bcd(const char** x) {
	clra			; uint16_t y = 0, d;
1	jsr	peekdig		; uint8_t a = 0, b, s[5];
	cmpb	#'0'		;
	blo	3f		; while (1) {
	cmpb	#'9'		;  b = peekdig(x, a);
	bhi	3f		;  if (b >= '0' && b <= '9') // verified a digit
	leax	1,x		;   if ((*x)++ // now *x points to a known digit
	leay	-5,y		;       &&
	bne	2f		;       (y != 5)) {
	leay	6,y		;
	andb	#$0f		;
	stb	,-s		;    s[y++] = b - '0';
	bra	1b		;    continue;
2	clrb			;   } else
	bra	5f		;    b = 0; // indicates unsuccessful conversion
3	tstb			;  break;
	beq	5f		; }
	cmpa	#'-'		; if ((d = b))
	beq			;  if (a != '-')
	jsr	d0to32k		;   d = y, y = d0to32k(y, s); // x is preserved
	bra			;  else
4	jsr	d16ngtv		;   d = y, y = d16ngtv(y, s); // =-d0to32k(y,s);
5	leas	d,s		; return b = d & 0x07; // total digits converted
	rts			;}
	
