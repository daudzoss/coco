 if 0
td0to19	orcc	#SEC		;1
	ldd	#9		;9
	ldx	#3		;3
	jsr	d0to199		;+
	tfr	x,y		;
	andcc	#CLC		;
	ldd	#0		;
	ldx	#7		;7
	jsr	d0to199		;=
	tfr	y,d		;
	abx			;2
	
	ldy	#$9a55
	cmpx	#$00c8		;0
	beq	1f		;0
	ldy	#$fa17		;F
1	swi			;P
 endif

 if 0
td8sgnd	orcc	#SEC		;1
	ldd	#2		;2
	ldx	#7		;7
	orcc	#SEN		;-
	jsr	d8sgnd		;+
	abx			;
	ldy	#$9a55		;
	cmpx	#$0100		;
	beq	1f		;
	ldy	#$fa17		;F
1	swi			;P
 endif
	
 if 1
tx10ind	ldx	#$0a		;
	jsr	x10ind		;
	ldy	#$9a55		;
	cmpd	#$0064		;
	beq	1f		;
	ldy	#$fa17		;
1	swi			;
 endif
