	include	"6809defs.s"
	include	"6809dB10.s"

	org	0x27ff
	swi
main	lda	#$00
	pshs	a
	
loop	ldb	#$03
	tf1pole
	;; plot D
	inc 	,s
	lda	,s
	bne	loop
	
	leas	1,s
done	bra	done
	end
