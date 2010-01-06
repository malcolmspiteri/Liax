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

all: create_build_dir stgone.bin stgtwo.bin

# Stage one boot loader

stgone.bin : 
	@echo "[ASM] $@"
	@$(ASM) $(SRC_DIR)/loader/stage_one/stgone.asm -f bin -o $(BUILD_DIR)/loader/stage_one/$@
	
# Stage two boot loader

stgtwo.bin : stgtwo.exe
	@$(OBJCOPY) -O binary $(BUILD_DIR)/loader/stage_two/$< $(BUILD_DIR)/loader/stage_two/$@
	
stgtwo.exe : stgtwo_main.o stgtwo_init.o
	@echo "[LD] $@"
	@$(LD) -T $(SRC_DIR)/loader/stage_two/link.ld -s -o $(BUILD_DIR)/loader/stage_two/$@ $(BUILD_DIR)/loader/stage_two/stgtwo_main.o $(BUILD_DIR)/loader/stage_two/stgtwo_init.o

stgtwo_main.o : 
	@echo "[CC] $@"
	@$(CC) -c -o $(BUILD_DIR)/loader/stage_two/$@ $(SRC_DIR)/loader/stage_two/stgtwo_main.c

stgtwo_init.o : 
	@echo "[ASM] $@"
	@$(ASM) $(SRC_DIR)/loader/stage_two/stgtwo_init.asm -f elf32 -o $(BUILD_DIR)/loader/stage_two/$@

# Initialization targets
	
create_build_dir:
	@echo "Creating build workspace"
	@$(MKDIR) $(MKDIR_FLAGS) ./build/loader/stage_one
	@$(MKDIR) $(MKDIR_FLAGS) ./build/loader/stage_two

clean:
	@echo "Removing generated binaries"
	@$(DELETE) $(DELETE_FLAGS) ./build
