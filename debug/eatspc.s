;;; eatspc.s
 if 0
	bra	skpinit
	ldx	#hellow		;
	jsr	eatspc		;
	ldb	hellow		;
	cmpb	#$0b		;
	beq	1f		;
	ldy	#$fa17		;
	swi			;
	
1	ldx	#patholo	;
	jsr	eatspc		;
	ldb	patholo		;
	cmpb	#$00		;
	beq	2f		;
	ldy	#$fa17		;
	swi			;
2	ldy	#$9a55		;
	swi			;
hellow	fcb	$0c
	fcc	"Hello world!"
patholo	fcb	$0c
	fcc	"            "
skpinit
 endif
