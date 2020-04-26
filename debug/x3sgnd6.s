;;; x3sgnd6.s
 if 1
	ldx	#$0000		;uint16_t x3divx2(void) {
	stx	,--s		; int16_t s[2];
	
0	ldx	,s		;
	leax	1,x		;
	stx	,s		;
	cmpx	#$0040		;
	bge	2f		;

	jsr	x3sgnd6		;
	ldx	,s		;
	jsr	x16divd		;
	ldx	,s		;
	jsr	x16divd		;
	ldx	,s		;
	std	,--s		;
	cmpx	,s++		;
	beq	0b		;

	
2	ldy	#$9a55		; }
	leas	4,s		; return 0x9a55; // PaSS
	swi			;} // mul8div8()
 endif
