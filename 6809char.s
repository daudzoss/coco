;;; compress ' ' out of a length-prefixed string in situ, update new length byte
eatspc	stx	,--s	; 9	;uint8_t eatspc(struct {uint8_t n;
	ldb	,x+	; 6	;                       char c[];}* str){
	incb		; 2	; uint8_t b = str->n + 1;
	tfr	x,y	; 6	; char* y, a;
	bra	2f	; 3	;
1	sta	,y+	; 6	; for (char* x = y = str->c; --b; x++)
2	decb		; 2	;
	beq	3f	; 3	;
	lda	,x+	; 6	;
	cmpa	#' '	; 2	;
	beq	2b	; 3	;  if ((a = *x) != ' ')
	bne	1b	; 3	;   *y++ = a;
3	tfr	y,d	; 6	;
	subd	,s	; 6	; // 0 <= x-y < 256 by definition
	comb		; 2	; b = -((uint16_t)str-y) - 1; // new string size
	ldx	,s++	; 8	;                             // is y - (str+1),
	stb	,x	; 4	; return str->n = b; // b <= length of original
	rts		;5(6169);} // eatspc()

;;; read a polynomial with int16_t coefficients, variables and uint2_t exponents
getpoly	cmpx	10,s	;	;int8_t getpoly(register char* x, int16_t s[5]){
	ble	5f	;	; while (x <= (char*)(s[5])) { // not at end yet
	jsr	get5bcd	; 	;  int16_t y, d = get5bcd(&x, &y); // past digit
	tstb		;	;
	beq	4f	;	;  if (d) { // successfully converted into Y
	lda	,x+	;	;   char a = *x++; // expecting var, +, - or end
	cmpa	#','	;	;
	bne	1f	;	;   if (a == ',') {// comma before initial guess
	jsr	get5bcd	;	;    uint8_t b = get5bcd(&x, &y);
	tstb		;	;    if (b == 0)
	beq	4f	;	;     return -1;// no value provided after comma
	bra	5f	;	;    break; // initial guess (or junk) is in y
1	deca		;	;
	anda	#$c0	;	;   } else if (a >= 'A') { // letter, maybe exp
	bne	2f	;	;
	ldb	,x+	;	;    char b = *x++;  // expecting 0,1,2,3,+ or -
	cmpb	#'0'	;	;
	blo	4f	;	;    if (b < '0')
	cmpb	#'4'	;	;     return -1;// invalid character encountered
	blo	3f	;	;    else if (b >= '4')
	ldb	#'1'	;	;     b = '1'; // implied exponent of 1
2
	leax	-1,x	;	;    else
3
	clra		;	;     ++x; // ate the exponent, so undo our --x:
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
	rts		;	;}
