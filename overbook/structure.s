SCREEN	equ	$0400		; location of screen memory

SEATWID	equ	$03		; pax about to sit are shown at +$00 +$03 +$06..
SEATPIT	equ	$40		; ..+$40 +$43..+$5a +$5d..+$80 +$83..+$9a +$9d..
WINDOW0	equ	$00		; pax at coordinate 0 has port window +$00 +$40
AISLE1	equ	$03		; pax at coordinate 3 to 9 is beyond left aisle
AISLE2	equ	$07		; pax at coordinate 7 to 9 is beyond right aisle
WINDOW3	equ	$09		; pax at coordinate 9 has starboard window +$1d
LASTROW	equ	$04		; pax can only sit in rows 0 through 4 inclusive
