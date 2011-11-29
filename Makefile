# Build tools
ASM=nasm
LD=ld
CC=gcc
OBJCOPY=objcopy

DELETE=rm
DELETE_FLAGS=-rf
MKDIR=mkdir
MKDIR_FLAGS=-p

# Directories
BASE_DIR=.
BUILD_DIR=$(BASE_DIR)/build
SRC_DIR=$(BASE_DIR)/SRC

all: create_build_dir stgone.bin stgopf.bin stgtwo.bin kernel.exe

# Stage-1 bootloader

stgone.bin : 
	@echo "[ASM] $@"
	@$(ASM) $(SRC_DIR)/loader/stage_one/stgone2.asm -f bin -d STGONE -o $(BUILD_DIR)/loader/stage_one/$@

# Stahe-1.5 bootloader

stgopf.bin : 
	@echo "[ASM] $@"
	@$(ASM) $(SRC_DIR)/loader/stage_opf/stgopf.asm -f bin -d STGOPF -d DEBUG_STGOPF -o $(BUILD_DIR)/loader/stage_opf/$@

# Stage-2 bootloader

stgtwo.bin : 
	@echo "[ASM] $@"
	@$(ASM) $(SRC_DIR)/loader/stage_two/stgtwo_init.asm -f bin -d STGTWO -o $(BUILD_DIR)/loader/stage_two/$@

kernel.exe : prekernel.exe
	@$(OBJCOPY) -S -R .note -R .comment -O binary $(BUILD_DIR)/kernel/$< $(BUILD_DIR)/kernel/$@

prekernel.exe : kernel_main.o
	@echo "[LD] $@"
	@$(LD) -T $(SRC_DIR)/kernel/link.ld -s -o $(BUILD_DIR)/kernel/$@ $(BUILD_DIR)/kernel/kernel_main.o

kernel_main.o : 
	@echo "[CC] $@"
	@$(CC) -c -o $(BUILD_DIR)/kernel/$@ $(SRC_DIR)/kernel/kernel_main.c

# Initialization targets

create_build_dir:
	@echo "Creating build workspace"
	@$(MKDIR) $(MKDIR_FLAGS) ./build/loader/stage_one
	@$(MKDIR) $(MKDIR_FLAGS) ./build/loader/stage_opf
	@$(MKDIR) $(MKDIR_FLAGS) ./build/loader/stage_two
	@$(MKDIR) $(MKDIR_FLAGS) ./build/kernel

clean:
	@echo "Removing generated binaries"
	@$(DELETE) $(DELETE_FLAGS) ./build
