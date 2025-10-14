// kernel/arch/power.zig - Power management functions
const io = @import("x86/io.zig");
const err = @import("../panic.zig");
const screens = @import("../ui/screens.zig");

// TODO: pub fn shutdown() noreturn {}
/// TODO: Implement ACPI shutdown properly
/// Currently just halts the system
// -----------------------------------
/// PS/2 Keyboard Controller reboot
pub fn reboot() noreturn {
    asm volatile ("cli"); // Disable interrupts
    // Trigger a keyboard controller reset
    const KBC_CMD: u16 = 0x64;
    const KBC_RESET: u8 = 0xFE;

    // Wait until input buffer is empty
    while ((@as(u8, io.inb(KBC_CMD)) & 0x02) != 0) {}

    // Send reset command
    io.outb(KBC_CMD, KBC_RESET);

    // If the system hasn't rebooted yet, halt
    busyWait(500);
    unreachable;
}

/// Sleep for specified milliseconds using timer (requires PIT initialized)
pub fn busyWait(milliseconds: u64) void {
    const iterations = milliseconds * 10 * 2000; // Assuming PIT frequency is 100Hz
    var i: u64 = 0;
    while (i < iterations) : (i += 1) {
        asm volatile ("nop");
    }
}

/// Halt the CPU indefinitely
pub fn halt() noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}
