 if 0
	orcc	#SEC		;1
	ldd	#$0009		;9
	ldx	#$0003		;3
	jsr	d0to199		;+
	tfr	x,y		;
	andcc	#CLC		;
	ldd	#$0000		;
	ldx	#$0007		;7
	jsr	d0to199		;=
	tfr	y,d		;
	abx			;2
	cmpx	#$00c8		;0
	beq	1f		;0
	ldy	#$fa17		;F
	swi
1	ldy	#$9a55
	swi			;P
 endif
