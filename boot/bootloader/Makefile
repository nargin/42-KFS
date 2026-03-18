ASM     = nasm
ASMFLAGS = -f bin
QEMU    = qemu-system-x86_64
QEMUFLAGS = -drive format=raw,file=$(TARGET)

SRC     = stage1.asm
TARGET  = bootloader.bin

.PHONY: all run clean

all: $(TARGET)

$(TARGET): $(SRC) helper.asm
	$(ASM) $(ASMFLAGS) -o $@ $<

run: $(TARGET)
	$(QEMU) $(QEMUFLAGS)

clean:
	rm -f $(TARGET)
