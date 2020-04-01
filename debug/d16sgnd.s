;;; d16sgnd.s
 if 0
	lda	#$01		;1
	sta	,-s		;
	lda	#$02		;2
	sta	,-s		;
	lda	#$03		;3
	sta	,-s		;
	lda	#$04		;4
	sta	,-s		;
	ldy	#$0004		;
	orcc	#SEN		;-
	jsr	d16sgnd		;
	leas	d,s		;
	
	tfr	y,d		;
	addd	#1234		;1
	beq	1f		;2
	ldy	#$fa17		;3
	swi			;4
1	ldy	#$9a55		;=
	swi			;0
 elsif 0
	ldd	#$0201		;
	std	,--s		;
	ldd	#$0403		;
	std	,--s		;
	ldy	#$0004		;
	orcc	#SEN		;-
	jsr	d16sgnd		;
	leas	d,s		;
	
	tfr	y,d		;
	addd	#1234		;
	beq	1f		;
	ldy	#$fa17		;
	swi			;
1	ldy	#$9a55		;
	swi			;
 endif

