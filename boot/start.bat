@ECHO OFF

@ECHO Assembling boot.asm
nasm boot.asm -f bin -o boot.bin

@ECHO Assembling MELOADER.ASM
nasm MELOADER.asm -f bin -o MELOADER.SYS

@ECHO Creating virtual floppy image
vfd OPEN B: C:\Projects\MeliteOS\resources\disk_images\1.img /NEW /W /144 /F
vfd FORMAT 1
rem format B: /A:512 /Q /FS:FAT /V:test

@ECHO Copying boot.bin to floppy image
partcopy boot.bin 0 200 -f1

@ECHO Copying MELOADER.asm to floppy image
copy MELOADER.SYS B:\

@ECHO Closing virtual floppy image
vfd CLOSE B:

@ECHO Invoking VM
start bochsrc.bxrc
