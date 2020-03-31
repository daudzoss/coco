 if 0
td0to19	orcc	#SEC		;1
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

 if 0
td8sgnd	orcc	#SEC		;1
	ldd	#$0002		;2
	ldx	#$0007		;7
	orcc	#SEN		;-
	jsr	d8sgnd		;+
	abx			;
	cmpx	#$0100		;
	beq	1f		;
	ldy	#$fa17		;F
	swi
1	ldy	#$9a55		;
	swi			;P
 endif
	
 if 0
tx10ind	ldx	#$000a		;a
	jsr	x10ind		;*
	ldy	#$9a55		;a
	cmpd	#$0064		;=
	beq	1f		;1
	ldy	#$fa17		;0
	swi			;0
1	ldx	#$f334		;-
	jsr	x10ind		;3
	cmpd	#$8008		;2
	beq	1f		;7
	ldy	#$fa17		;6
	swi			;*
1	ldy	#$9a55		;a
	swi
 endif

 if 0
td16pst	lda	#$01		;
	sta	,-s		;
	lda	#$02		;
	sta	,-s		;
	lda	#$03		;
	sta	,-s		;
	lda	#$04		;
	sta	,-s		;
	ldy	#$0004		;
	jsr	d16pstv		;
 elsif 1
td16pst	ldd	#$0403		;
	std	,--s		;
	ldd	#$0201		;
	std	,--s		;
	ldy	#$0004		;
	jsr	d16pstv		;
 endif
	swi
