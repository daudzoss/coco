mathfunc.bin : mathfunc.s 6809defs.s 6809test.s 6809char.s 6809math.s
	asm6809 mathfunc.s -s mathfunc.sym -l mathfunc.lst -o mathfunc.bin -C

6809test.s : 
	touch 6809test.s

nodebug : 
	echo -n > 6809test.s

debug : 6809test.s debug/*.s
	cat debug/*.s > 6809test.s

emu : mathfunc.bin
	xroar -machine coco2bus -cart edtasm+ mathfunc.bin
