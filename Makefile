mathfunc.bin : mathfunc.s 6809defs.s 6809test.s 6809char.s 6809math.s
	asm6809 mathfunc.s -s mathfunc.sym -l mathfunc.lst -o mathfunc.bin -C --define SIZE_OVER_SPEED

6809test.s : 
	touch 6809test.s

clean :
	echo -n > 6809test.s

debug : 6809test.s debug/*.s
	cat debug/*.s > 6809test.s

emu : mathfunc.bin
	xroar -machine coco2bus -cart edtasm+ -cart-autorun mathfunc.bin

pdf : mathfunc.lst
	enscript -r mathfunc.lst -o mathfunc.ps && ps2pdf mathfunc.ps && atril mathfunc.pdf

