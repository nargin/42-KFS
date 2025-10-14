// drivers/pit.zig - Programmable Interval Timer (PIT) driver
const io = @import("../arch/x86/io.zig");

/// Wont be used for now, im not really sure how to implement it properly
const PIT_FREQUENCY: u32 = 1193182; // Hz
const PIT_CHANNEL0: u16 = 0x40;
const PIT_COMMAND: u16 = 0x43;

var system_ticks: u64 = 0;
var ticks_per_second: u32 = 0;

/// Initialize PIT to fire at specified frequency (Hz)
pub fn init(frequency: u32) void {
    ticks_per_second = frequency;

    // Calculate divisor
    const divisor: u16 = @intCast(PIT_FREQUENCY / frequency);

    // Send command byte: Channel 0, lobyte/hibyte, rate generator
    io.outb(PIT_COMMAND, 0x36);

    // Send divisor
    io.outb(PIT_CHANNEL0, @intCast(divisor & 0xFF));
    io.outb(PIT_CHANNEL0, @intCast((divisor >> 8) & 0xFF));
}

pub fn tick() void {
    system_ticks += 1;
}

pub fn getTicks() u64 {
    return system_ticks;
}

pub fn getFrequency() u32 {
    return ticks_per_second;
}

/// Convert milliseconds to ticks
pub fn msToTicks(milliseconds: u64) u64 {
    return (milliseconds * ticks_per_second) / 1000;
}
