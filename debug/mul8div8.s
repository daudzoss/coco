;;; mul8div8.s
 if 1
	ldx	#$ff80		;uint16_t mul8div8(void) {
	stx	,--s		; int16_t s[2];
	clr	,--s		; for (s[1] = 0xff81; s <= 0x007f; s[1]++) {
	
0	ldx	2,s		;  if (s[1] == 0)
	leax	1,x		;
	stx	2,s		;
	beq	0b		;   continue; // avoid eventual division by 0
	cmpx	#$0080		;  for (s[0] = 0x0000; s <= 0xffff; s[0]++) {
	bge	2f		;   int16_t x = s[1]; // 8b signed multiplicand

	ldd	,s		;   int16_t d = s[0]; // 16b signed multiplicand
	cmpd	#$8000		;   if (d == 0x8000) // skip special "NaN" value
	beq	1f		;    continue;
	jsr	x8mul16		;   d = x8mul16(x, d); // d *= x;
	ldx	2,s		;   x = s[1];
	jsr	x16divd		;   d = x16divd(d, x); // d /= x;
	cmpd	,s		;
	beq	1f		;   if (d != s[0])
	ldx	2,x		;    // x will hold divisor that failed check
	ldy	#$fa17		;    // d will hold failed quotient, s[0] actual
	leas	4,s		;    return 0xfa17; // faIL
	swi			;    // so dividend that failed check was x*s[0]
	
1	addd	#$0001		;
	std	,s		;
	bra	0b		;  }
	
2	ldy	#$9a55		; }
	leas	4,s		; return 0x9a55; // PaSS
	swi			;} // mul8div8()
 endif
