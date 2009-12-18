@ECHO OFF

@ECHO Assembling boot.asm
nasm boot.asm -f bin -o boot.bin

@ECHO Assembling melsetup.asm
nasm MELOADER.asm -f bin -o MELOADER.SYS

@ECHO Creating virtual floppy image
vfd OPEN E:\Projects\MeliteOS\resources\disk_images\1.img /NEW /W /144 /F
vfd FORMAT 0
rem format A: /A:512 /Q /FS:FAT /V:test

@ECHO Copying boot.bin to floppy image
partcopy boot.bin 0 200 -f0

@ECHO Copying MELOADER.asm to floppy image
copy MELOADER.SYS A:\

@ECHO Closing virtual floppy image
vfd CLOSE

@ECHO Invoking VM
start bochsrc.bxrc
