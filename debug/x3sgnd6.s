;;; x3sgnd6.s
 if 1;//fixme: x3sgnd6() probably does have major bugs
	ldx	#$0000		;{
	leas	-2,s		;
	
1	leax	1,x		;
	stx	,s		;
	cmpx	#$0040		;
	bhi	2f		;

	jsr	x3sgnd6		;
	ldx	,s		;
	jsr	x16divd		;
	ldx	,s		;
	jsr	x16divd		;
	ldx	,s		;
	std	,s		;
	cmpx	,s		; for (x = 1; x < 1<<6; x++) {
	beq	1b		;  d = x * x * x; // x3sgnd6() under test
	ldy	#$fa17		;  if (d / x / x != x)
	bra	3f		;   return 0xfa17;
2	ldy	#$9a55		; }
3	leas	2,s		; return 0x9a55;
	swi			;}
 endif
