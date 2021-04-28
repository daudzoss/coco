;;;  D = Dx5(D)
;;;  quickly multiply a quantity by 5 by shifting and adding
;;;
;;;          16_15_14_13_12_11_10_ 9_ 8_ 7_ 6_ 5_ 4_ 3_ 2_ 1_ 0_
;;;  input:      0 <------- nonnegative integer <= 26214 ------> in D (A:B)
;;;  output: <--------- nonnegative integer <= 131070 ---------> in C:D (C:A:B)
Dx5	macro
	std	,--s		;inline uint17_t Dx5(register uint15_t d) {
	lslb			;
	rola			;
	lslb			;
	rola			; return d += (d << 2); // d *= 5;
	addd	,s++		;} // Dx5()
	endm

;;;  D = logcomp(D)
;;;  implement a piecewise convex 16b normalized function approximating log2(x+1)
;;;
;;;          16_15_14_13_12_11_10_ 9_ 8_ 7_ 6_ 5_ 4_ 3_ 2_ 1_ 0_
;;;  input:     <-------- fraction normalized to 65536 --------> in D (A:B)
;;;  output:    <-------- fraction normalized to 65536 --------> in D (A:B)
logcomp	macro
	bitb	#$f0		;inline uint8_t logcomp(register uint8_t b) {
	beq	slope2c		; switch (b & 0xf0) {
	stb	,-s		;
	andb	#$e0		;
	cmpb	#$e0		; case 0xe0:
	bne	slope1c		; case 0xf0:
slope0c	ldb	,s+		;
	lsrb			;  return b = b * 1/2 + 0x80;
	addb	#$80		; case 0x00:
	bra	1f		;  return b = b * 2;
slope2c	lslb			; default:
	bra	1f		;  return b = b * 1 + 0x10;
slope1c	ldb	,s+		; }
	addb	#$10		;} // logcomp()
1
	endm
	
;;;  D = logexpa(D)
;;;  implement a piecewise concave 16b normalized function approximating 2^x - 1
;;;
;;;          16_15_14_13_12_11_10_ 9_ 8_ 7_ 6_ 5_ 4_ 3_ 2_ 1_ 0_
;;;  input:     <-------- fraction normalized to 65536 --------> in D (A:B)
;;;  output:    <-------- fraction normalized to 65536 --------> in D (A:B)

;;;  D = log2(D)
;;;  approximate log base 2 of a 16 bit integer retaining 12 bits after leading 1
;;;
;;;          16_15_14_13_12_11_10_ 9_ 8_ 7_ 6_ 5_ 4_ 3_ 2_ 1_ 0_
;;;  input:     <---------- positive integer <= 65528 ---------> in D (A:B)
;;;  output:    <fbits 11:8><truncd log><-- fraction bits 7:0 -> in D (A:B)
log2	macro
	orcc	#SEC		;inline uint16_t log2(register uint16_t d) {
	rolb			; register uint1_t c;
	rola			; c = (d >> 15) & 1;
	bcs	log2_15		; d = (d << 1) | 0x0001; // (12 >> 3) & 1
	orcc	#SEC		; if (!c) { // bit 15 zero
	rolb			;  c = (d >> 15) & 1;
	rola			;  d = (d << 1) | 0x0001; // (12 >> 2) & 1
	bcs	log2_14		;  if (!c) { // bits 15 and 14 zero
	rolb			;   c = (d >> 15) & 1;
	rola			;   d = (d << 1) | 0x0000; // (12 >> 1) & 1
	bcs	log2_13		;   if (!c) { // bits 15, 14 and 13 zero
	rolb			;    c = (d >> 15) & 1;
	rola			;    d = (d << 1) | 0x0000; // (12 >> 0) & 1
	bcs	log2ans		;    if (c) return d = (d << 8)|((d >> 8)&0xff);
1	subb	#1		;
	bitb	#$0f		;
	beq	log2ans		;    for (uint4_t b = 11; b; b--) {
	lslb			;     c = (d >> 15) & 1;
	rola			;     d <<= 1;
	pshs	cc		;
	stb	,-s		;
	andb	#$e0		;     // just the 3 lowest-order bits
	lsl	,s		;
	lsl	,s		;
	lsl	,s		;     // stack now holds b << 4
	lsr	,s		;
	lsr	,s		;
	lsr	,s		;
	lsr	,s		;     // stack now holds b in the range 0 to 11
	orb	,s+		;     // lowest-order bits in hi nybble, b in lo
	puls	cc		;     if (c) return d = (((d & 0xf0) | b) << 8)
	bcs	log2ans		;                           | ((d >> 8) & 0xff);
	bra	1b		;    }
log2_13	andb	#$f0		;   } else // bit 13 holds the leftmost 1
	orb	#$0d		;    return d = (d << 8) | ((d >> 8)&0xf0) | 13;
	bra	log2ans		;
log2_14	andb	#$f0		;  } else // bit 14 holds the leftmost 1
	orb	#$0e		;   return d = (d << 8) | ((d >> 8)&0xf0) | 14;
	bra	log2ans		;
log2_15	andb	#$f0		; } else // bit 15 holds the leftmost 1
	orb	#$0f		;  return d = (d << 8) | ((d >> 8)&0xf0) | 15;
log2ans	exg	a,b		;} // log2()
	endm

;;;  D = dB10(D)
;;;  a quick piecewise approximation to log base 10 of a 16 bit integer, times 10
;;;
;;;          16_15_14_13_12_11_10_ 9_ 8_ 7_ 6_ 5_ 4_ 3_ 2_ 1_ 0_
;;;  input:     <---------- positive integer <= 65528 ---------> in D (A:B)
;;;  output:    <fbits 11:8><truncd log><-- fraction bits 7:0 -> in D (A:B)
dB10	macro
	log2
	anda	#$0f		;register uint14_t dB10(register uint16_t d) {
	logcomp
	Dx5
	Dx5
	rora			; d = log2(d); // log10(d) == log2(d)/log2(10)
	rolb			; d = (d & 0x0f00) | logcomp(d & 0x00ff);
	lsra			; d = d * 25 / 8; // == d * 100/32 ~= d * 10/3.3
	rolb			;
	lsra			; return d; // 10log10(d) in a, fractional in b
	rolb			;} // dB10()
	endm
normal macro
1      tst     ,s	;inline
       beq     2f	;
       lsr     a	;
       rol     b	;
       if \1 > 1
        lsr    a	;
        rol    b	;
        if \1 > 2
         lsr   a	;
         rol   b	;
         if \1 > 3
          lsr  a	;
          rol  b	;
          if \1 > 4
           lsr a	;
           rol b	;
          endif
         endif
        endif
       endif
       dec     ,s	;
       bra     1b	;}
2
       endm

