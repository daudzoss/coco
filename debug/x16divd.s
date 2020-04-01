;;; x16divd.s
 if 0
	ldd	#$8001		;-
	ldx	#$2000		;3
	jsr	x16divd		;2
	cmpd	#$fffc		;k
	beq	1f		;/
	ldy	#$fa17		;8
	swi			;k
	

1	ldy	#$9a55
	swi
 endif
