;;; compress ' ' out of a length-prefixed string in situ, update new length byte
eatspc	stx	,--s	; 9	;void eatspc(struct {uint8_t n;// length byte
	ldb	,x+	; 6	;                       char c[];}* str){
	incb		; 2	; uint8_t b = str->n + 1;
	tfr	x,y	; 6	; char* y, a;
	bra	2f	; 3	;
1	sta	,y+	; 6	; for (char* x = y = str->c; --b; x++)
2	decb		; 2	;
	beq	3f	; 3	;
	lda	,x+	; 6	;
	cmpa	#' '	; 2	;
	bne	1b	; 3	;  if ((a = *x) != ' ')
	beq	2b	; 3	;   *y++ = a;
3	tfr	y,d	; 6	;
	subd	,s	; 6	; // 0 <= x-y < 256 by definition
	addb	#0xff	; 2	; b = y - (1 + (uint16_t)str);// new string size
	ldx	,s++	; 8	;                             // is y - (str+1),
	stb	,x	; 4	; str->n = b; // b <= length of original
	tfr	x,d	; 6	; return d = x; // FIXME: only for ECB testing
	rts		;5(6169);} // eatspc()

;;; look ahead to next character in the array, plus one more if it's a +/- sign
peekdig	ldb	,x	; 2	;char peekdig(const char** x, char* a/*zero*/) {
	tsta		; 2	; char b = *(*x);
	bne	4f	; 3	; if (a == '\0') { no sign found yet
	cmpb	#'-'	; 2	;
	beq	1f	; 3	;
	cmpb	#'+'	; 2	;
	bne	4f	; 3	;  if (b == '-' || b == '+') { // first sign  
1	lda	,x+	; 4	;   *a = b; // gets stored in *a to remember '-'
	ldb	,x	; 2	;   b = *++(*x); // then advance *x pointer once
	cmpb	#'0'	; 2	;
	blo	2f	; 3	;
	cmpb	#'9'	; 2	;
	bhi	2f	; 3	;   if (b >= '0' && b <= '9')
	rts		; 2	;    ; // digit follows sign as expected
2	andb	#0xdf	; 2	;
	cmpb	#'A'	; 2	;   else if (toupper(b) >= 'A' &&
	blo	3f	; 3	;            toupper(b) <= 'Z')
	cmpb	#'Z'	; 2	;    b = 1; // variable follows sign; coeff is 1
	bhi	3f	; 3	;   else b = 0; // not a digit, sign, or letter
	ldb	#$01	; 2	;  }
	rts		;	; }
3	clrb		;	; return b;
4	rts		; 5 (40);} // peekdig()
