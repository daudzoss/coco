;;; compress ' ' out of a length-prefixed string in situ, update new length byte
eatspc	stx	,--s	; 9	;void eatspc(struct {uint8_t n; char* c;}* str){
	ldb	,x+	; 6	; uint8_t b = str->n;
	tfr	x,y	; 7	; char* y = str->c, a;
	bra	2f	; 3	;
1	sta	,y+	; 6	; for (char* x = y; b--; x++)
2	decb		; 2	;
	bmi	3f	; 3	;
	lda	,x+	; 6	;
	cmpa	#' '	; 2	;
	beq	2b	; 3	;  if ((a = *x) != ' ')
	bne	1b	; 3	;   *y++ = a;
3	tfr	y,d	; 7	;
	subd	,s	; 6	; b = y - x; // (negative) delta in string size
	addd	,s	; 6	;
	ldx	,s++	; 8	;
	stb	,x	; 4	; str->n += b; // less than or equal to original
	rts		;5(6425);} // eatspc()

	bita	#$fe	; 	;
	beq	notstring
	
;;; read a polynomial with int16_t coefficients, variables and uint2_t exponents
getpoly	leax	1,x	; 5	; for (char* x = str->c; x <= final; ) {
1
	cmpx	8,s	;	;  int16_t y, d;
	ble	5f	;	;  uint8_t b = get5bcd(&x, &y); // past digits
	jsr	get5bcd	; 	;
	tstb		;	;  if (b) { // successfully converted into Y
	beq	error
	lda	,x+	;	;   char a = *x++; // expecting var, +, - or end
	cmpa	#','	;	;
	bne	2f	;	;   if (a == ',') {// comma before initial guess
	jsr	get5bcd	;	;    b = get5bcd(&x, &y);
	tstb		;	;    if (b == 0)
	beq	error	;	;     goto error;
	sty	8,s	;	;    final.i = y;
	bra	?	;	;    break;
2	deca		;	;
	anda	#$c0	;	;   } else if (a >= 'A') { // letter, maybe exp
	bne	3f	;	;
	ldb	,x+	;	;    char b = *x++;  // expecting 0,1,2,3,+ or -
	cmpb	#'0'	;	;
	blo	error	;	;
	cmpb	#'4'	;	;
	blo	4f	;	;    if (b < '0' || b >= '4')
	ldb	#'1'	;	;     b = '1'; // implied exponent of 1
3
	leax	-1,x	;	;    else
4
	clra		;	;     ++x; // ate the exponent, so undo the --x:
	aslb		;	;   } // we now have coefficient in y, exp in b
	andb	0x06	;	;   --x; // back up to get potential next term
	sty	d,s	;	;   s[b -'0'] = y;
	bra	1b	;	;  }
5

??
