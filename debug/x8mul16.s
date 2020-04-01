;;; x8mul16
 if 1
	ldx	#$0017
	ldd	#$0242
	jsr	x8mul16
	cmpd	#$33ee
	beq	1f
	ldy	#$fa17
	swi
	
1	ldx	#$00f8
	ldd	#$fffa
	jsr	x8mul16
	cmpd	#$0030
	beq	1f
	ldy	#$fa17
	swi

1	ldy	#$9a55
	swi
 endif
