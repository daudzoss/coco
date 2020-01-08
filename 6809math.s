;;; convert a 3-digit unsigned BCD 0..199 to binary unsigned in X
d0to199	lda	#$0a	; 2	;uint16_t d0to199(uint1_t c,  // 100's
	bcc	1f	; 3	;                 uint8_t b,   // 10's
	addb	#$0a	; 2	;                 uint16_t x) { // 1's
1	mul		;11	; uint16_t d = 10*(c*10 + b); c = d & 0x80;
	abx		; 2	; return x += d & 0xff; // = c*100 + b*10
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
	addd	,s++	; 9	; return d += d*4; // = x*10
	rts		; 2 (35);} // x10inD()

;;; convert a Y-digit unsigned BCD 0..32767 to binary unsigned in X, copy Y to D
d0to32k	ldx	#$0000	; 3	;uint16_t d0to32k(uint3_t y,
	sty	,--s	; 9	;                 uint8_t* s) {
	beq	2f	; 3	; uint16_t x, d = y; // digit count y <= 5
1	jsr	x10ind	; 8 (43); for (x = 0x0000; y; y--) {
	leax	4,s	; 5 	;  // d is now x*10, x is now the digit pointer
	exg	d,x	; 7	;  x *= 10; // d is now the digit pointer
	ldb	d,y	; 8	;  uint8_t b = s[ /* 4 + */ y];
	abx		; 3	;  x += b;
	leay	-1,y	; 5	; }
	bne	1b	; 3	; // caller can pop d args with: leas d,s
2	ldd	,s++	; 8	; return d, x;
	rts		; 2(395);} // d0to32k()

;;; convert a Y-digit signed BCD -32767..32767 to binary signed in X,copy Y to D
d16sgnd	bmi	1f	; 3	;int16_t d16sgnd(uint1_t n,
	jsr	d0to32k	; 8(403);                uint3_t y,
	rts		; 2	;                uint8_t* s) {
1	jsr	d0to32k	; 8(403); uint16_t x, d = y; // digit count y <= 5
	exg	x,d	; 7	;
	coma		; 2	;
	comb		; 2	; // 
	addd	#$0001	; 4	; // caller can pop d args with: leas d,s
	exg	x,d	; 7	; return d, x = d0to32k(y, s) * (n ? -1 : 1);
	rts		; 2(430);} // d16sgnd()
