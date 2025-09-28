// kernel/panic.zig
const vga = @import("drivers/vga.zig");
const Color = @import("common/types.zig").Color;

pub fn panic(message: []const u8) noreturn {
    asm volatile ("cli"); // Disable interrupts

    // Clear screen with red background to show panic
    vga.clearScreen(Color.makeColor(Color.White, Color.Red));

    // Display panic header
    vga.putStringCentered(5, "!!! KERNEL PANIC !!!", Color.makeColor(Color.Yellow, Color.Red));
    vga.putStringCentered(7, message, Color.makeColor(Color.White, Color.Red));

    // Additional debug info
    vga.putStringCentered(10, "System halted - reboot required", Color.makeColor(Color.LightGray, Color.Red));

    halt();
}

pub fn halt() noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}
