ASM=nasm
LD=ld
CC=gcc
OBJCOPY=objcopy
DELETE=rm

loader.bin : loader.exe
	@$(OBJCOPY) -O binary $< $@

loader.exe : loader.o loader_start.o
	@echo "[LD] $@"
	@$(LD) -T link.ld -s -o loader.exe loader.o loader_start.o

loader.o : 
	@echo "[CC] $@"
	@$(CC) -c -o $@ loader.c

loader_start.o : 
	@echo "[ASM] $@"
	@$(ASM) loader_start.asm -f win32 -o $@

clean :
	@echo "Removing generated binaries"
	@$(DELETE) *.o
	@$(DELETE) *.exe
	@$(DELETE) *.bin
