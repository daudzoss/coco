mathfunc.bin : mathfunc.s 6809defs.s 6809char.s 6809math.s
	asm6809 mathfunc.s -s mathfunc.sym -l mathfunc.lst -o mathfunc.bin -C

emu : mathfunc.bin
	xroar mathfunc.bin


