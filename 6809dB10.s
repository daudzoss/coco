Dx5	macro
	std	,--s		;inline uint17_t Dx5(register uint15_t d) {
	lslb			;
	rola			;
	lslb			;
	rola			; return d + (d << 2); // d *= 5;
	addd	,s++		;} // Dx5()
	endm

logcomp	macro
	bitb	#$f0		;inline uint8_t logcomp(register uint8_t b) {
	beq	slope2c		; switch (b & 0xf0) {
	stb	,-s		;
	andb	#$e0		;
	cmpb	#$e0		; case 0xe0:
	bne	slope1c		; case 0xf0:
slope0c	
	ldb	,s+		;
	lsrb			;  return b / 2;
	addb	#$80		; case 0x00:
	bra	1f		;  return b * 2 + 0x80; 
slope2c
	lslb			; default:
	bra	1f		;  return b * 1 + 0x10;
slope1c
	ldb	,s+		; }
	addb	#$10		;} // logcomp()
1
	endm
	
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
	bcs	log2ans		;    if (c) return (d << 8) | ((d >> 8) & 0xff);
log2_lp	subb	#1		;
	bitb	#$0f		;
	beq	log2ans		;    for (uint4_t b = 11; b; b--) {
	lslb			;     c = (d >> 15) & 1;
	rola			;     d <<= 1;
	pshs	cc,b		;
	andb	#$e0		;     // just the 3 lowest-order bits
	lsl	,s		;
	lsl	,s		;
	lsl	,s		;     // stack now holds b << 4
	lsr	,s		;
	lsr	,s		;
	lsr	,s		;
	lsr	,s		;     // stack now holds b
	orb	,s+		;     // lowest-order bits in hi nybble, b in lo
	puls	cc		;     if (c) return (((d & 0x00f0) | b) << 8) |
	bcs	log2ans		;                             ((d >> 8) & 0xff);
	bra	log2_lp		;    }
log2_13
	andb	#$f0		;   } else // bit 13 holds the leftmost 1
	orb	#$0d		;    return (d << 8) | ((d >> 8) & 0xf0) | 13;
	bra	log2ans		;
log2_14
	andb	#$f0		;  } else // bit 14 holds the leftmost 1
	orb	#$0e		;   return (d << 8) | ((d >> 8) & 0xf0) | 14;
	bra	log2ans		;
log2_15
	andb	#$f0		; } else // bit 15 holds the leftmost 1
	orb	#$0f		;  return  (d << 8) | ((d >> 8) & 0xf0) | 15;
log2ans
	exg			;}
	endm

dB10
