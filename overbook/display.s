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
	bra	end_of_function	;  return; // *x and *y dimensions unclobbered
2	tfr	pc,y		; } else { // rotate counter?clockwise by 90
rotate2	leay	rotbuf-rotate2,y;
	;ldy	#rotbuf
	bra	3f		;
rotbuf	rmb	5*4		;  static uint8_t rotbuf[4/*cols*/ * 5/*rows*/];
3	sta	3,s		;  *y = a; // new height
	stb	1,s		;  *x = b; // new width
	mul			;
	pshs	b		;  uint8_t s = a*b;
	lda	#5*4		;  for (uint8_t* x=d, int a=19; a >= 0; a--)
4	deca			;
	ldb	a,x		;
	cmpa	,s		;
	blo	5f		;
	ldb	#-1		;
5	stb	a,y		;
	tsta			;
	bne	4b		;   rotbuf[a] = (a < s) ? x[a] : -1;
	leay	d,y		;  for (uint8_t* y = &(rotbuf[a*b - 1]); s; y--)
	ldb	1+1,s		;
	abx			;
	leax	-1,x		;   for (uint8_t* x = &(d[b-1]); *x>=0; x += b){
	pshs	x		;
7	dec	2,s		;    s--;
	lda	,-y		;
	sta	,x		;
	abx			;
	lda	,x		;
	bpl	7b		;    *x = *y;
	puls	x		;
	leax	-1,x		;
	tst	2,s		;   }
	bne	6b		;

;;; idea: use abx with x as a negative offset to move through buffer?

end_of_function
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
	
