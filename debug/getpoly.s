;;; getpoly.s
 if 1
chkpoly	macro
	ldb	poly\1	; 2	;{
	ldx	#poly\1	; 3	; char* x;
	leas	-10,s	; 5	; uint16_t s[5], y, coeff[4];
	abx		; 3	; // push the last character of string to stack:
	stx	8,s	; 9	; s[4] = (uint16_t) (poly + (char*) *poly);
	ldx	#0	; 3	;
	stx	6,s	; 6	; s[3] = 0; // x^3 coeff at stack pointer + 6
	stx	4,s	; 6	; s[2] = 0; // x^2 coeff at stack pointer + 4
	stx	2,s	; 6	; s[1] = 0; // x^1 coeff at stack pointer + 2
	stx	0,s	; 6	; s[0] = 0; // x^0 coeff at stack pointer + 0
	ldx	#1+poly\1;3	; x = &poly[1];// past size byte to string start
	jsr	getpoly	; 7 ( )	; getpoly(x, s);
	ldy	#$fa17	;	;
	ldd	3+coeff\1	;
	cmp	,s++		; if (s[1] != coeff[0])
	bne	0f		;  return y = 0xfa17; // faIL
	ldd	2+coeff\1	;
	cmp	,s++		; if (s[2] != coeff[1])
	bne	0f		;  return y = 0xfa17; // faIL
	ldd	1+coeff\1	;
	cmp	,s++		; if (s[3] != coeff[3])
	bne	0f		;  return y = 0xfa17; // faIL
	ldd	0+coeff\1	;
	cmp	,s++		; if (s[4] != coeff[4])
	bne	0f		;  return y = 0xfa17; // faIL
	ldy	#$9a55		; return y = 0x9a55; // PaSS
0	leas	10,s		;}
	endm

1	chkpoly	1
	cmpy	#$9a55		;
	beq	2f		;
	swi
2	chkpoly	2
	cmpy	#$9a55		;
	beq	3f		;
3	swi
	
poly1	fcb	poly2-poly1-1
	fcc	"1x2-6x+9"
poly2	fcb	poly3-poly2-1
	fcc	"x2-7x+12"
poly3

coeff1	fcw	0
	fcw	1
	fcw	-6
	fcw	9
coeff2	fcw	0	
	fcw	1
	fcw	-7
	fcw	12

coeff3
 endif
