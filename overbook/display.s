rotate	pshs	y,x		;void rotate(uint16_t*x, uint16_t*y, uint_8* d){
	tfr	d,x		;
	lda	1,s		; uint8_t a = *x; // old width of card to rotate
	ldb	3,s		; uint8_t b = *y;// old height of card to rotate
	cmpb	#4		;
	bls	2f		; if (b > 4) { // too wide if rotated 90 degrees
	tfr	x,y		;  uint8_t* x = d, * y = d;
	mul			;  for (b = a * b - 1; b >= 0; b--) {
1	decb			;
	lda	b,x		;
	sta	,-s		;   uint8_t s = x[b];
	lda	,y		;
	sta	b,x		;   x[b] = *y;
	lda	,s+		;
	sta	,y+		;
	tstb			;   *y++ = s;
	bne	1b		;  } // reversing the array rotated it by 180
	bra	end_of_function
	puls	x,y		;  return; // x and y unchanged
	rts			; } else { // rotate counter?clockwise by 90
rotbuf	rmb	5*4		;  static uint8_t rotbuf[4/*cols*/ * 5/*rows*/];
2	sta	3,s		;  *y = a; // new height
	stb	1,s		;
	exg	a,b		;  *x = b; // new width
	ldy	#rotbuf		;  uint8_t* x = d;
	ldb	#5*4		;  for (b = a * b - 1; b >= 0; b--)
	pshs	u		;
3	addb	#-2		;
	ldu	b,x		;
	stu	b,y		;
	tstb			;
	bne	3b		;   rotbuf[b] = x[b];
	puls	u		;

;;; idea: use abx with x as a negative offset to move through buffer?


	puls	x,y		;
	rts			;} // rotate()

toowide	abx			;toowide(uint8_t b, uint16_t* x) { // pos,width
	cmpb	#AISLE2		;
	blo	1f		;
	cmpx	#1+WINDOW3	; if (b >= AISLE2)
	rts			;  return (*x += b) > WINDOW3;
1	cmpb	#AISLE1		;
	blo	2f		;
	cmpx	#AISLE2		; else if (b >= AISLE1)
	rts			;  return (*x += b) >= AISLE2;
2	cmpx	#AISLE1		; else return (*x += b) >= AISLE1;
	rts			;} // toowide()

toolong	sty	,--s		;toolong(uint8_t* a, uint16_t y) { // pos,length
	exg	a,b		;
	addd	,s++		;
	exg	a,b		;
	cmpa	#1+LASTROW	; return (*a += y) > LASTROW;
	rts			;} // toolong()

pax2scr	stb	,-s		;uint16_t pax2scr(uint8_t a, uint8_t b) { // r,c
	lslb			; uint8_t s = b;
	addb	,s		; b = (b << 1) + s; // b *= SEATWID;
	cmpb	#SEATWID*AISLE2	;
	blo	1f		; if (b >= SEATWID * AISLE2)
	incb			;  b++;
1	cmpb	#SEATWID*AISLE1	;
	blo	2f		; if (b >= SEATWID * AISLE1)
	incb			;  b++;
2	stb	,s		;
	lsra			;
	rolb			;
	lsra			;
	rolb			;
	andb	#SEATPIT-1	;
	orb	,s+		; return d = a * SEATPIT + b;
	rts			;} // pax2scr()
	
