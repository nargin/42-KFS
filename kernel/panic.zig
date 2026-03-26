const vga = @import("drivers/vga.zig");
const Color = vga.Color;

pub fn halt() noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}

pub fn panic(message: []const u8) noreturn {
    asm volatile ("cli");
    vga.clearScreen(Color.make(Color.White, Color.Red));
    vga.putStringCentered(5, "!!! KERNEL PANIC !!!", Color.make(Color.Yellow, Color.Red));
    vga.putStringCentered(7, message, Color.make(Color.White, Color.Red));
    vga.putStringCentered(10, "System halted - reboot required", Color.make(Color.LightGray, Color.Red));
    halt();
}
