BUILD_DIR := zig-out/bin
ISO_DIR := isodir/boot
GRUB_DIR := $(ISO_DIR)/grub

# Targets
KERNEL := $(BUILD_DIR)/kernel.elf
ISO := kernel.iso

# Zig build command
ZIG_BUILD := zig build

.PHONY: all clean run

all: $(ISO)

$(KERNEL):
	$(ZIG_BUILD)

$(ISO): $(KERNEL)
	@mkdir -p $(GRUB_DIR)
	@cp $(KERNEL) $(ISO_DIR)
	@cp boot/grub.cfg $(GRUB_DIR)
	grub-mkrescue -o $(ISO) isodir

clean:
	rm -rf zig-out kernel.iso isodir

run: $(ISO)
	qemu-system-x86_64 -cdrom $(ISO) -m 512M -serial stdio -no-reboot -no-shutdown

re: clean all run