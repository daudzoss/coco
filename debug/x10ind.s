 if 0
	ldx	#$000a		;a
	jsr	x10ind		;*
	ldy	#$9a55		;a
	cmpd	#$0064		;=
	beq	1f		;1
	ldy	#$fa17		;0
	swi			;0
1	ldx	#$f334		;-
	jsr	x10ind		;3
	cmpd	#$8008		;2
	beq	2f		;7
	ldy	#$fa17		;6
	swi			;*
2	ldy	#$9a55		;a
	swi
 endif
