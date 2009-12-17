@ECHO OFF

@ECHO Assembling boot.asm
nasm boot.asm -f bin -o boot.bin

@ECHO Assembling melprenv.asm
nasm melprenv.asm -f bin -o MELPRENV.SYS

@ECHO Creating virtual floppy image
vfd OPEN E:\Projects\MeliteOS\disk_images\1.img /NEW /W /144 /F
format A: /A:512 /Q /FS:FAT /V:Melite

@ECHO Copying boot.bin to floppy image
partcopy boot.bin 0 200 -f0

@ECHO Copying MELPRENV.SYS to floppy image
copy MELPRENV.SYS A:\

@ECHO Closing virtual floppy image
vfd CLOSE
