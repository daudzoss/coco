eatspc	stx	,--s	; 9	;void eatspc(struct {uint8_t n; char* c;}* str){
	ldb	,x+	; 	; uint8_t b = str->n;
	tfr	x,y	; 	; char* y = str->c, a;
	bra	2f	; 	;
1	sta	,y+	; 	; for (char* x = y; b--; x++)
2	decb		; 	;
	bmi	3f	; 	;
	lda	,x+	; 	;
	cmpa	#' '	; 	;
	beq	2b	; 	;  if ((a = *x) != ' ')
	bne	1b	; 	;   *y++ = a;
3	tfr	y,d	; 	;
	subb	,s	; 	; b = y - x; // negative delta in string size
	ldx	,s	; 	;
	abx		; 	;
	tfr	x,d	; 	;
	ldx	,s++	; 	;
	stb	,x	; 	; str->n += b; // less than or equal to original
	rts		;	;} // eatspc()
