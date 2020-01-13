;;; compress ' ' out of a length-prefixed string in situ, updating the size byte
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
	ldx	,s	; 5	;
	abx		; 3	;
	tfr	x,d	; 7	;
	ldx	,s++	; 8	;
	stb	,x	; 4	; str->n += b; // less than or equal to original
	rts		;5(6434);} // eatspc()
