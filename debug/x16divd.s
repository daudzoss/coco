;;; x16divd.s
 if 1
	ldd	#$8001		;-
	ldx	#$2000		;3
	jsr	x16divd		;2
	cmpd	#-3		;k
	beq	1f		;/
	ldy	#$fa17		;8
	swi			;k
	
1	ldd	#$7fff		;3
	ldx	#$e001		;2
	jsr	x16divd		;k
	cmpd	#-4		;/
	beq	2f		;-
	ldy	#$fa17		;8
	swi			;k
	
2	ldy	#$9a55
	swi
 endif
