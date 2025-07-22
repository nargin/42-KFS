BUILD_DIR := zig-out/bin
ISO_DIR := isodir/boot
GRUB_DIR := $(ISO_DIR)/grub

# Targets
KERNEL := $(BUILD_DIR)/kernel.elf
ISO := kernel.iso

ZIG_BUILD := zig build

.PHONY: all clean run

all: $(ISO)

$(KERNEL):
	$(ZIG_BUILD)

$(ISO): $(KERNEL)
	@mkdir -p $(GRUB_DIR)
	@cp $(KERNEL) $(ISO_DIR)
	@cp boot/grub.cfg $(GRUB_DIR)
	grub-mkrescue -o $(ISO) isodir \
		--install-modules="multiboot" \
		--compress=xz \
		--locales="" \
		--themes="" \
		--fonts=""


clean:
	rm -rf zig-out kernel.iso isodir

run: $(ISO)
	qemu-system-x86_64 -cdrom $(ISO) -vga std -m 512M -serial stdio -no-reboot -no-shutdown

re: clean all run