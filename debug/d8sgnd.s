 if 0
	orcc	#SEC		;1
	ldd	#$0002		;2
	ldx	#$0007		;7
	orcc	#SEN		;-
	jsr	d8sgnd		;+
	abx			;
	cmpx	#$0100		;
	beq	1f		;
	ldy	#$fa17		;F
	swi
1	ldy	#$9a55		;
	swi			;P
 endif
