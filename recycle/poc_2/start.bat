@ECHO OFF

@ECHO Assembling boot.asm
nasm boot.asm -f bin -o boot.bin

@ECHO Creating virtual floppy image
vfd OPEN D:\Projects\MelitaOS\disk_images\1.img /NEW /W /144 /F

@ECHO Copying boot.bin to floppy image
partcopy boot.bin 0 200 -f0

@ECHO Closing virtual floppy image
vfd CLOSE

del "C:\Virtual Machines\1.flp"
copy "D:\Projects\MelitaOS\disk_images\1.img" "C:\Virtual Machines\1.flp"