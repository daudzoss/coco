;;; mul8div8.s
 if 1
	
	ldx	#$0017
	ldd	#$0242
	jsr	x8mul16
	ldx	#$0017
	jsr	x16divd
	cmpd	#$0242
	beq	1f
	ldy	#$fa17
	swi
	
1	ldy	#$9a55
	swi
 endif
