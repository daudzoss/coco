eatspc	stx	,--s	; 9	;void eatspc(struct {uint8_t n; char* c;}* str){
	ldb	,x+	; 	; uint8_t b = str->n;
	tfr	x,y	; 7	; char* y = str->c, a;
	bra	2f	; 3	;
1	sta	,y+	; 	; for (char* x = y; b--; x++)
2	decb		; 2	;
	bmi	3f	; 3	;
	lda	,x+	; 	;
	cmpa	#' '	; 2	;
	beq	2b	; 3	;  if ((a = *x) != ' ')
	bne	1b	; 3	;   *y++ = a;
3	tfr	y,d	; 7	;
	subd	,s	; 	; b = y - x; // (negative) delta in string size
	ldx	,s	; 	;
	abx		; 	;
	tfr	x,d	; 7	;
	ldx	,s++	; 	;
	stb	,x	; 	; str->n += b; // less than or equal to original
	rts		; 5	;} // eatspc()
