;;; d16pstv.s
 if 0
	lda	#$01		;
	sta	,-s		;
	lda	#$02		;
	sta	,-s		;
	lda	#$03		;
	sta	,-s		;
	lda	#$04		;
	sta	,-s		;
	ldy	#$0004		;
	jsr	d16pstv		;
	leas	d,s		;
	swi			;
 elsif 0
	ldd	#$0304		;
	std	,--s		;
	ldd	#$0102		;
	std	,--s		;
	ldy	#$0004		;
	jsr	d16pstv		;
	leas	d,s		;
	swi			;
 endif

