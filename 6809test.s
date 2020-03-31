#if 0
td0to19	orcc	#SEC		;1
	ldb	#9		;9
	ldx	#3		;3
	jsr	d0to199		;+
	tfr	x,y		;
	andcc	#CLC		;
	ldb	#0		;
	ldx	#7		;7
	jsr	d0to199		;=
	tfr	y,d		;
	abx			;2
	ldy	#$9a55
	cmpx	#$00c8		;0
	beq	1f		;0
	ldy	#$fa17		;F
1	swi			;P
#endif

#if 1
td8sgnd	

tx10ind	
