const vga = @import("drivers/vga.zig");
const Color = vga.Color;

pub fn halt() noreturn {
    asm volatile ("cli");
    while (true) {
        asm volatile ("hlt");
    }
}

pub fn reboot() noreturn {
    asm volatile ("outb %[v], %[p]"
        :
        : [v] "{al}" (@as(u8, 0xFE)),
          [p] "N" (@as(u8, 0x64)),
    );
    halt();
}

pub fn shutdown() noreturn {
    // Only works in QEMU: writing 0x2000 to port 0x604 triggers ACPI S5 power-off.
    // On real hardware this port is unknown and the write is ignored, falling into halt.
    // 0x604 = QEMU's virtual power management port
    asm volatile ("outw %[v], %[p]"
        :
        : [v] "{ax}" (@as(u16, 0x2000)),
          [p] "{dx}" (@as(u16, 0x604)),
    );
    halt();
}

pub fn panic(message: []const u8) noreturn {
    // asm volatile ("cli");
    vga.clearScreen(Color.make(Color.White, Color.Red));
    vga.putStringCentered(5, "!!! KERNEL PANIC !!!", Color.make(Color.Yellow, Color.Red));
    vga.putStringCentered(7, message, Color.make(Color.White, Color.Red));
    vga.putStringCentered(10, "System halted - reboot required", Color.make(Color.LightGray, Color.Red));
    halt();
}
