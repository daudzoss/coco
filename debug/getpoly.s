;;; getpoly.s
 if 1 ; // something rotten in the state of getpoly()
	jmp	coeff4
chkpoly	macro
	ldb	poly\1	; 2	;uint16_t chkpoly(char poly[],uint16_t coeff[]){
	ldx	#poly\1	; 3	; char* x;
	leas	-10,s	; 5	; uint16_t s[5], y;
	abx		; 3	; // push the last character of string to stack:
	stx	8,s	; 9	; s[4] = (uint16_t) (poly + (char*) *poly);
	ldx	#0	; 3	;
	stx	6,s	; 6	; s[3] = 0; // x^3 coeff at stack pointer + 6
	stx	4,s	; 6	; s[2] = 0; // x^2 coeff at stack pointer + 4
	stx	2,s	; 6	; s[1] = 0; // x^1 coeff at stack pointer + 2
	stx	0,s	; 6	; s[0] = 0; // x^0 coeff at stack pointer + 0
	ldx	#1+poly\1;3	; x = &poly[1];// past size byte to string start
	jsr	getpoly	; 7 ( )	; getpoly(x, s);
	ldy	#$fa17	; 4	;
	ldd	6+coeff\1;5	;
	cmpd	6,s	; 8	; if (s[3] != coeff[3])
	bne	0f	; 3	;  return y = 0xfa17; // faIL
	ldd	4+coeff\1;5	;
	cmpd	4,s	; 8	; if (s[2] != coeff[2])
	bne	0f	; 3	;  return y = 0xfa17; // faIL
	ldd	2+coeff\1;5	;
	cmpd	2,s	; 8	; if (s[1] != coeff[1])
	bne	0f	; 3	;  return y = 0xfa17; // faIL
	ldd	0+coeff\1;5	;
	cmpd	0,s	; 8	; if (s[0] != coeff[0])
	bne	0f	; 3	;  return y = 0xfa17; // faIL
	ldy	#$9a55	; 5	; return y = 0x9a55; // PaSS
0	leas	10,s	; 5	;}
	endm

1	chkpoly	1
	cmpy	#$9a55		;
	beq	2f		;
	swi			;
	
2	chkpoly	2
	cmpy	#$9a55		;
	beq	3f		;
	swi			;
	
3	chkpoly	3		;
	cmpy	#$9a55		;
	beq	4f		;
4	swi

poly1	fcb	poly2-poly1-1
	fcc	"1x2-6x+9"
poly2	fcb	poly3-poly2-1
	fcc	"x2-7x+12"
poly3	fcb	poly4-poly3-1
	fcc	"8x3+8"
poly4
	
coeff1	fdb	9
	fdb	-1
	fdb	1
	fdb	0
coeff2	fdb	12	
	fdb	-7
	fdb	1
	fdb	0
coeff3	fdb	8
	fdb	0
	fdb	0
	fdb	8
coeff4
 endif
