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
	cmpb	#'-'	; 2	; char b = *(*x);
	bne	2f	; 3	;
	tsta		; 2	; if (b == '-' || b == '+') {
	bne	4f	; 3	;  if (*a == '\0') { // first character found
1	lda	,x+	; 4	;   *a = b; // gets stored in *a to remember '-'
	ldb	,x	; 2	;   b = ++(*x); // then advance *x pointer once
	cmpb	#'0'	; 2	;
	blo	3f	; 3	;
	cmpb	#'9'	; 2	;
	bhi	3f	; 3	;   
	rts		; 2	;
2	cmpb	#'+'	; 2	;   // but if the next character after a sign
	bne	4f	; 3	;   // isn't a digit or letter i.e. a variable
	tsta		; 2	;   // with coeff 1, there is an error condition
	beq	1b	; 3	;   if (b < '0' || b > '9')
	bne	4f	; 3	;    b = (b & 0xc0) ? /*implicit*/ 1 : 0/*err*/;
3	andb	#$40	; 2	;  }
	beq	4f	; 3	; }
	ldb	#$01	; 2	; return b;
4	rts		; 5 (40);} // peekdig()
