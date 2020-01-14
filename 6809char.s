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
getpoly	jsr	eatspc	;8(6433);int16_t getpoly(struct {uint8_t n; char* c;}*
	stx	,--s	; 9	;                str)
	clra		; 2	; char* x, * final; // stack pointer + 8
	ldb	[,s]	;	;
	addd	,s	;	; eatspc(); 
	std	,s	; 	; final = str + str->n;

	leas	-8,s	; 	; uint16_t s[4] = {
	clr	,s	; 6	;  0, // x^0 coefficient at stack pointer + 0
	clr	1,s	; 7	;
	clr	2,s	; 7	;  0, // x^1 coefficient at stack pointer + 2
	clr	3,s	; 7	;
	clr	4,s	; 7	;  0, // x^2 coefficient at stack pointer + 4
	clr	5,s	; 7	;
	clr	6,s	; 7	;  0  // x^3 coefficient at stack pointer + 6
	clr	7,s	; 7	; };
	
	lda	,x+;replaces:
	ldb	#1	;	;
	abx		;	; for (char* x = str->c; x <= final; ) {
1
	cmpx	8,s	;	;  int16_t y;
	ble	alldone
	jsr	get5bcd	; 	;  b = get5bcd(&x, &y); // advanced past dig
	tstb		;	;
	beq	error
	lda	,x	;	;  if (b) { // successfully converted into Y
	cmp	#','	;	;
	bne	2f	;	;   if (*x == ',') { // comma for initial guess
	lda	,x+
;;;store initial value overwriting s[8]
2	anda	#$fe	;	;   } else if (*x & 0xc0) { // letter
	bne	nonletter




	ldd	2,s	;
	ora	4,s	;
	ora	5,s	;
	ora	6,s	;
	ora	7,s	;
	beq	f
	dec	2,s	;	; if (!s[1] && !s[2] && !s[3]) {
	dec	3,s	;	;  s[1] = -1; // calculator mode
	ldd	,s	;	;  ?? = -s[0]; // initial guess will be exact
	std	??
