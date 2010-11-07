@ECHO OFF

@ECHO Creating virtual floppy image
vfd OPEN A: C:\Users\malcolm\Projects\MeliteOS\test\img\floppy.img /NEW /W /144 /F
vfd FORMAT 0 
rem format A: /A:512 /Q /FS:FAT /V:test

@ECHO Copying boot.bin to floppy image
copy C:\Users\malcolm\Projects\MeliteOS\build\loader\stage_one\stgone.bin .
partcopy stgone.bin 0 200 -f0
del .\stgone.bin

@ECHO Copying MELOADER.SYS to floppy image
copy C:\Users\malcolm\Projects\MeliteOS\build\loader\stage_two\stgtwo.bin A:\MELOADER.SYS

@ECHO Copying KERNEL.EXE to floppy image
copy C:\Users\malcolm\Projects\MeliteOS\build\kernel\kernel.exe A:\KERNEL.EXE

@ECHO Closing virtual floppy image
vfd CLOSE A:

@ECHO Invoking VM
start C:\Users\malcolm\Projects\MeliteOS\test\bochsrc.bxrc
