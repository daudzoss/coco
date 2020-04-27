;;; x3sgnd6.s
 if 1;//fixme: x3sgnd6() probably does have major bugs
	ldx	#$ffe0		;{
	leas	-2,s		; for (int16_t x = -(1<<5) + 1; x < 1<<5; x++) {
	
0	leax	1,x		;
	stx	,s		;
	cmpx	#$0040		;
	bge	3f		;
	
	jsr	x3sgnd6		;  int16_t d = x * x * x; // function under test
	ldx	,s		;
	bne	1f		;  if (x == 0) {
	cmpd	#0		;   if (d == 0)
	beq	0b		;    continue; // explicit check that 0*0*0=0
	bra	2f		;   return 0xfa17; // faIL
1	jsr	x16divd		;  }
	ldx	,s		;
	jsr	x16divd		;
	ldx	,s		;
	std	,s		;
	cmpx	,s		;
	beq	0b		;
2	ldy	#$fa17		;  if (d / x / x != x)
	bra	4f		;   return 0xfa17; // faIL
3	ldy	#$9a55		; }
4	leas	2,s		; return 0x9a55; // PaSS
	swi			;}
 endif
