#include "c2/motorola/6809.s"

                        // ustack

                        @ = $0000
start:          rts
end:
	
stringa:


numtoab:
	lda	,u		;uint16_t numtoab(void* u) {
	tfr	a,b		; int8_t a, b;
	bmi	numtoab1	; b = a = * (uint8_t*) u;
	lda	#$00		;
	beq	numtoab4	; if (a & 0x80) { // msb set means not a string
numtoab1:
	anda	#$03		;  switch (a & 0x03) { // embedded nybble format
	bne	numtoab2	;
	aslb			;
	asrb			;
	asrb			;
	asrb			;   case 0:
	asrb			;    b = ((b & 0x40) ? 0xf0 : 0x00) | (b >> 3);
	rts			;    return (0 << 8) | b; // a=0, -8 < b < 7
numtoab2:
	ldb	1,u		;   case 1: return (1 << 8) | ((uint8_t*) u)[1];
	cmpa	#$03		;   case 2: return (2 << 8) | ((uint8_t*) u)[1];
	bne	numtoab3	;   case 3: return (4 << 8) | ((uint8_t*) u)[1];
	inca			;  } // MSB in b, size in a, Z flag per a
numtoab3:
	rts			; } else
numtoab4:
	;; could parse a string for int8_t here into a with stringa() if desired
	exg	a,b		;  return (a=b) | 0; // string of len b, not num
	rts			;} // numtoab()


prevnumd:
	tfr	u,y		;int16_t prevnumd(void* u) {
	jsr	numtoab		;  void* y = u; // u stashed in y
	inca			;  uint8_t a = (numtoab(u) >> 8)+ 1; // to skip
	leau	a,u		;  u += a;
	jsr	numtoab		;  int16_t d = numtoab(u);
	bita	#$04		;  switch (d >> 8) {
	beq	prevnum2	;   case 4:
	bita	#$02		;    break; // Z set means 32-bit can't fit in d
	bne	prevnum1	;   case 2:
	lda	2,u		;    d = (((int8_t*)u)[2] << 8) | (d & 0x00ff);
	leay	,y		;    break; // Z flag will be cleared
	bra	prevnum2	;   default:
prevnum1:
	tfr	b,a	 	;    d = (d << 8); // Z flag will be cleared
	ldb	#$00		;  }
	leay	,y		;  d = (d << 8) | (d >> 8); // make big-endian
prevnum2:
	tfr	y,u		;  u = y; // u restored from y
	exg	a,b		;  return d; // if Z is set, it was 32 bits long
	rts			;} // prevnumd()


multbyt:
	jsr	prevnumd	;uint16_t multbyt(void* u) {
	beq	multerr		; int16_t d = prevnum(u);
	anda	#$ff		; if ((d < 0) || (d > 255)) // || 32 bits long
	bne	multerr		;  return 65555; // Z flag will be set as well
	lda	#$81		; ((uint8_t*)u)[-1] = d & 0x00ff;
	pshu	b,a		; ((uint8_t*)u)[-2] = 0x80 /*num*/ | 1 /*byte*/;
	jsr	prevnumd	;
	beq	multerr		; d = prevnum(&u[-2]);
	anda	#$ff		; if ((d < 0) || (d > 255)) // || 32 bits long
	bne	multerr		;  return 65535; // Z flag will be set as well
	pulu	a		;
	pulu	a		; uint8_t a = ((uint8_t*)u)[-1]; 
	mul			; uint8_t b = d & 0x00ff;
	rts			; return a * b; // Z only set if a==0 or b==0
multerr:
	ldy	#$ffff		;
	ldd	#$0000		;
	exg	d,y		;
	rts			;} // multbyt

addbyt:
	
