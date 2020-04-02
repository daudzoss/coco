;;; get5bcd.s
 if 1
	ldx	#lit32k
	jsr	get5bcd
	cmpy	#$7fff
	beq	1f
	ldy	#$fa17
	swi
	
1	ldx	#lit_32k
	jsr	get5bcd
	cmpy	#$8001
	beq	2f
	ldy	#$fa17
	swi
2	ldy	#$9a55
	swi
	
lit_32k fcc	"-"
lit32k	fcc	"32767"
	fcb	0
 endif
