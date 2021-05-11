;;; X,Y = rotate(X,Y,D)
;;; rotate a 2D nonnegative byte pattern 90 degrees (up to 4x4) or 180 (if Nx5)
;;;
;;;         16_15_14_13_12_11_10_ 9_ 8_ 7_ 6_ 5_ 4_ 3_ 2_ 1_ 0_
;;; input:                                            [cols<=4] in X
;;; input:                                            [rows<=5] in Y
;;; input:     [     pointer to 20-byte array <= 65516        ] in D (A:B)
;;; output:                                           [cols<=4] in X
;;; output:                                           [rows<=5] in Y
;;;
;;; e.g.
;;; input:               X = 3
;;;         $01    $04    $02
;;; Y = 2   $00    $03    $05 (in memory as $01,$04,$02,$00,$03,$05,...)
;;;                     <----
;;; output:       X = 2
;;;         $02    $05 |
;;;         $04    $03 V
;;; Y = 3   $01    $00 (in memory as $02,$05,$04,$03,$01,$00,$00,$00,$00,$00...)
rotate	pshs	y,x		;void rotate(uint16_t*x, uint16_t*y, uint_8* d){
	tfr	d,x		;
	lda	1,s		; uint8_t a = *x; // old width of card to rotate
	ldb	3,s		; uint8_t b = *y;// old height of card to rotate
	cmpb	#4		;
	bls	2f		; if (b > 4) { // too wide if rotated 90 degrees
	tfr	x,y		;  uint8_t* x = d, * y = d;
	mul			;  for (uint8_t b = a * b - 1; b >= 0; b--) {
1	decb			;
	lda	b,x		;
	sta	,-s		;   uint8_t s = x[b];
	lda	,y		;
	sta	b,x		;   x[b] = *y;
	lda	,s+		;
	sta	,y+		;
	tstb			;   *y++ = s;
	bne	1b		;  } // reversing the array rotated it by 180
	bra	9f		;  // *x and *y dimensions unclobbered
	
2	tfr	pc,y		; } else { // rotate counter?clockwise by 90
rotate2	leay	rotbuf-rotate2,y;
	;ldy	#rotbuf
	bra	3f		;  static uint8_t rotbuf[5/*rows*/ * 4/*cols*/];
rotbuf	rmb	5*4
3	sta	3,s		;  *y = a; // new height
	stb	1,s		;  *x = b; // new width
	mul			;
	pshs	b		;  uint8_t s = a*b;// entries actually populated
	lda	#5*4		;  for (uint8_t* x=d, int a=19; a >= 0; a--)
4	deca			;
	ldb	a,x		;
	cmpa	,s		;
	blo	5f		;
	ldb	#$ff		;
5	stb	a,y		;
	tsta			;
	bne	4b		;   rotbuf[a] = (a < s) ? x[a] : -1;
	
	ldb	,s		;
	leay	d,y		;
	ldb	1+1,s		;
	abx			;  for (uint8_t* y = &(rotbuf[a*b - 1]); s; y--)
6	leax	-1,x		;   for (uint8_t* x = &(d[b-1]); *x>=0; x += b){
	pshs	x		;
7	dec	2,s		;    s--;
	lda	,-y		;
	sta	,x		;
	abx			;
	lda	,x		;    *x = *y;
	bpl	7b		;   } // rotated each rotbuf row into a column
	puls	x		;
	tst	,s		;
	bne	6b		;
	leas	1,s		;
	lda	3,s		;
	ldb	1,s		;
	mul			;  for (uint8_t* x = &(d[a*b]); x<&(d[5*4]);x++)
	;lda	#0		;
8	cmpb	#5*4		;
	beq	9f		;
	sta	b,x		;
	incb			;
	bra	8b		;   *x = 0;// clear out -1 delimiter from rotbuf

9	puls	x,y		; } // x and y dimension exchanged if 90 degrees
	rts			;} // rotate()

;;; CC = toowide(B,X)
;;; set conditions according to whether a card at B of width X fits its section
;;;
;;;         16_15_14_13_12_11_10_ 9_ 8_ 7_ 6_ 5_ 4_ 3_ 2_ 1_ 0_
;;; input:                             [   col position <= 9  ] in D (B)
;;; input:                                            [cols<=4] in X
;;; output:                            [ suitable for BLO/BGE ] in CC
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

;;; CC = toolong(A,Y)
;;; set conditions according to whether a card at A of length Y fits its section
;;;
;;;         16_15_14_13_12_11_10_ 9_ 8_ 7_ 6_ 5_ 4_ 3_ 2_ 1_ 0_
;;; input:     [  row position <= 4   ]                         in D (A)
;;; input:                                            [rows<=5] in Y
;;; output:                            [ suitable for BLO/BGE ] in CC
toolong	sty	,--s		;toolong(uint8_t* a, uint16_t y) { // pos,length
	exg	a,b		;
	addd	,s++		;
	exg	a,b		;
	cmpa	#1+LASTROW	; return (*a += y) > LASTROW;
	rts			;} // toolong()

;;; D = pax2scr(A,B)
;;; return screen offset from upper left to preview passenger seat row a, col b
;;; (the pax final seat location after moving/rotating is $11=33 greater)
;;;
;;;         16_15_14_13_12_11_10_ 9_ 8_ 7_ 6_ 5_ 4_ 3_ 2_ 1_ 0_
;;; input:     [  row position <= 4   ][  col position <= 9   ] in D (A:B)
;;; output:                         [    screen cell <= 511   ] in D (A:B)
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
	
