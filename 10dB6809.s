logcomp	macro
	endm
	
log2	macro
	sec			;inline uint16_t log2(register uint16_t d) {
	rolb			; register uint1_t c = d & (1 << 15);
	rola			;
	bcs	log2_15		; d = (d << 1) | 0x0001;
	sec			; if (!c) {
	rolb			;  c = d & (1 << 15);
	rola			;  d = (d << 1) | 0x0001;
	bcs	log2_14		;  if (!c) {
	rolb			;   c = d & (1 << 15);
	rola			;   d = (d << 1);
	bcs	log2_13		;   if (!c) {
	rolb			;    c = d & (1 << 15);
	rola			;    d = (d << 1); 
	bcs	log2ans		;    if (c) return;// 12 MSB: fraction, 4 LSB: C
log2_lp	subb	#1		;
	bitb	#$0f		;
	beq	log2ans		;
	lslb			;
	pshs	cc		;
	rol	,s+		;	
	rola			;	
	bcs	log2ans		;
	
log2ans
	endm

