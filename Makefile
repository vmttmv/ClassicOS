AS = nasm
ASFLAGS = -f elf32 -g -F dwarf
CC = gcc
LD = ld
QEMU= qemu-system-i386

BUILD_DIR = build
DISK_IMG = $(BUILD_DIR)/disk.img
STAGE2_SIZE = 2048

all: $(DISK_IMG)

.PHONY: stage1 stage2 kernel clean
stage1: $(BUILD_DIR)
	$(AS) $(ASFLAGS) -o $(BUILD_DIR)/$@.o bootloader/$@.asm
	$(LD) -Ttext=0x7c00 -melf_i386 -o $(BUILD_DIR)/$@.elf $(BUILD_DIR)/$@.o
	objcopy -O binary $(BUILD_DIR)/$@.elf $(BUILD_DIR)/$@.bin

# NOTE: Stage2 final size should be checked against `$(STAGE2_SIZE)` by the build system to avoid an overflow.
# Alternatively, convey the final stage2 size through other means to stage1.
stage2: $(BUILD_DIR)
	$(AS) $(ASFLAGS) -o $(BUILD_DIR)/$@.o bootloader/$@.asm
	$(LD) -Ttext=0x7e00 -melf_i386 -o $(BUILD_DIR)/$@.elf $(BUILD_DIR)/$@.o
	objcopy -O binary $(BUILD_DIR)/$@.elf $(BUILD_DIR)/$@.bin
	truncate -s $(STAGE2_SIZE) $(BUILD_DIR)/$@.bin

# Dummy kernel target so we have something to load
kernel: $(BUILD_DIR)
	echo "THIS IS A DUMMY PAYLOAD KERNEL" > $(BUILD_DIR)/kernel.bin
	truncate -s 4096 $(BUILD_DIR)/kernel.bin

$(DISK_IMG): stage1 stage2 kernel
	dd if=$(BUILD_DIR)/stage1.bin of=$@
	dd if=$(BUILD_DIR)/stage2.bin of=$@ oflag=append conv=notrunc
	dd if=$(BUILD_DIR)/kernel.bin of=$@ oflag=append conv=notrunc

$(BUILD_DIR):
	mkdir -p $@

clean:
	rm -rf $(BUILD_DIR)
