;;; get3bcd.s
 if 1
	ldx	#lit127
	jsr	get3bcd
	cmpy	#$007f
	beq	1f
	ldy	#$fa17
	swi
	
1	ldx	#lit_127
	jsr	get3bcd
	cmpy	#$0081
	beq	2f
	ldy	#$fa17
	swi
2	ldy	#$9a55
	swi
	
lit_127 fcc	"-"
lit127	fcc	"127"
 endif
