@ECHO OFF

copy /Y C:\Users\malcolm\Projects\MeliteOS\test\img\floppy_base.img C:\Users\malcolm\Projects\MeliteOS\test\img\floppy.img
@ECHO Creating virtual floppy image
vfd OPEN A: C:\Users\malcolm\Projects\MeliteOS\test\img\floppy.img /W /144 /F

@ECHO Copying stgone.bin to floppy image
copy C:\Users\malcolm\Projects\MeliteOS\build\loader\stage_one\stgone.bin .
partcopy stgone.bin 0 1FF -f0
del .\stgone.bin
@ECHO Copying stgopf.bin to floppy image
copy C:\Users\malcolm\Projects\MeliteOS\build\loader\stage_opf\stgopf.bin .
partcopy stgopf.bin 0 E00 -f0 200
del .\stgopf.bin

@ECHO Copying MELOADER.SYS to floppy image
copy C:\Users\malcolm\Projects\MeliteOS\build\loader\stage_two\stgtwo.bin A:\MELOADER.SYS

@ECHO Copying KERNEL.EXE to floppy image
copy C:\Users\malcolm\Projects\MeliteOS\build\kernel\kernel.exe A:\KERNEL.EXE

@ECHO Closing virtual floppy image
vfd CLOSE A:

@ECHO Invoking VM
start C:\Users\malcolm\Projects\MeliteOS\test\bochsrc.bxrc