;;; get3bcd.s
 if 0
	ldx	#lit127		;
	jsr	get3bcd		;
	cmpd	#$007f		;
	beq	1f		;
	ldy	#$fa17		;
	swi			;
	
1	ldx	#lit_127	;
	jsr	get3bcd		;
	cmpd	#$ff81		;
	beq	2f		;
	ldy	#$fa17		;
	swi			;
	
2	ldx	#toolong	;
	jsr	get3bcd		;
	cmpd	#$8000		;
	beq	3f		;
	ldy	#$fa17		;
	swi			;
	
3	ldy	#$9a55		;
	swi			;
	
lit_127 fcc	"-"
lit127	fcc	"127"
	fcb	$0d
toolong	fcc	"1234"
;	fcb	$0d		;<--FIXME: causes program not to load!!!
 endif
