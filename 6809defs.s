;	if $
;	else
;	org	0xc000
;	endif

	if SIZE_OVER_SPEED
	elsif SPEED_OVER_SIZE
	else
SPEED_OVER_SIZE	equ	1	; default
	endif

SEC	equ	$01
CLC	equ	~SEC	

SEV	equ	$02
CLV	equ	~SEV

SEZ	equ	$04
CLZ	equ	~SEZ

SEN	equ	$08
CLN	equ	~SEN

SEI	equ	$10
CLI	equ	~SEI

SEH	equ	$20
CLH	equ	~SEH

SEF	equ	$40
CLF	equ	~SEF

SEE	equ	$80
CLE	equ	~SEE
