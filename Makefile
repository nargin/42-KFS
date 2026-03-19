BUILD_DIR := zig-out/bin
ISO_DIR := isodir/boot
GRUB_DIR := $(ISO_DIR)/grub

GRUB_MKRESCUE := $(shell command -v i686-elf-grub-mkrescue 2>/dev/null || command -v grub-mkrescue 2>/dev/null || echo grub-mkrescue)

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
# 	strip --strip-all -R .comment -R .note $(KERNEL) # if anything goes wrong remove this, can messup with MAGIC number not in grub scanning range
	@cp $(KERNEL) $(ISO_DIR)
	@cp boot/grub.cfg $(GRUB_DIR)
	$(GRUB_MKRESCUE) -o $(ISO) isodir \
		--install-modules="multiboot" \
		--compress=xz \
		--locales="" \
		--themes="" \
		--fonts=""


clean:
	rm -rf zig-out kernel.iso isodir

run: $(ISO)
	qemu-system-x86_64 -cdrom $(ISO) -vga std

check-size:
	@size=$$(du -b kernel.iso | cut -f1); \
	limit=$$((10 * 1024 * 1024)); \
	echo "ISO size: $$(du -sh kernel.iso | cut -f1)"; \
	if [ $$size -gt $$limit ]; then \
			echo "ERROR: exceeds 10MB ($$size bytes)"; exit 1; \
	else \
			echo "OK: within 10MB limit"; \
	fi

re: clean all run check-size