;;; convert a 3-digit unsigned BCD 0..199 to binary unsigned in X
d0to199	lda	#$0a	; 2	;uint16_t d0to199(uint1_t c,  // 100's
	bcc	1f	; 3	;                 uint8_t b,   // 10's
	addb	#$0a	; 2	;                 uint16_t x) { // 1's
1	mul		;11	; uint16_t d = 10*(c*10 + b);
	abx		; 2	; return x += c*100 + b*10;
	rts		; 2 (22);} // d0to199()

;;; convert a 3-digit signed BCD -128..127 to binary unsigned in X, signed in D
d8signd	jsr	d0to199	; 8 (30);int16_t d8signd(uint1_t n, // sign
	tfr	x,d	; 7	;                uint1_t c,  // 100's
	bpl	1f	; 3	;                uint16_t d,  // 10's
	negb		; 2	;                uint16_t x) { // 1's
	sex		; 2	; return d = (x += c*100 + b*10) * (n ? -1 : 1);
1	rts		; 2 (46);} // d8signed()

;;; multiply X -3276..3276 by 10 into D, e.g. to allow 5-digit BCD construction
x10tod	stx	temp2dp	; 5	;int16_t x10tod(int16_t x,
	asl	temp2dp	; 6	;               int16_t* temp2dp) {
	ldd	temp2dp	; 5	;
	aslb		; 2	;
	rola		; 2	;
	aslb		; 2	;
	rola		; 2	; *temp2dp = x * 2;
	addd	temp2dp	; 6	; return d = x * 10;
	rts		; 2 (32);} // x10tod()

;;;
d0to32k
