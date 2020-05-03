;;; eatspc.s
 if 0
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
hellow	fcb	patholo-hellow-1
	fcc	"Hello world!"
patholo	fcb	lastone-patholo-1
	fcc	"            "
lastone
 endif
