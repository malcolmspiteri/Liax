@ECHO OFF

@ECHO Creating virtual floppy image
vfd OPEN B: C:\Projects\MeliteOS\test\img\floppy.img /NEW /W /144 /F
vfd FORMAT 1
rem format B: /A:512 /Q /FS:FAT /V:test

@ECHO Copying boot.bin to floppy image
copy C:\Projects\MeliteOS\build\loader\stage_one\stgone.bin .
partcopy stgone.bin 0 200 -f1
del .\stgone.bin

@ECHO Copying MELOADER.SYS to floppy image
copy C:\Projects\MeliteOS\build\loader\stage_two\stgtwo.bin B:\MELOADER.SYS

@ECHO Copying KERNEL.EXE to floppy image
copy C:\Projects\MeliteOS\build\kernel\kernel.exe B:\KERNEL.EXE

@ECHO Closing virtual floppy image
vfd CLOSE B:

@ECHO Invoking VM
start C:\Projects\MeliteOS\test\bochsrc.bxrc
