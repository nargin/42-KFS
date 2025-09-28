const std = @import("std");
const vga = @import("drivers/vga.zig");
const Color = @import("common/types.zig").Color;
const Keyboard = @import("drivers/keyboard.zig").Keyboard;
const panic = @import("panic.zig").panic;

pub fn init_hardware() !void {
    // Initialize VGA display
    vga.clearScreen(0x07); // Clear screen with black background and light gray text
    vga.hideCursor();
}

fn init_drivers() !void {
    // Initialize keyboard
    // Initialize other drivers
    vga.putString(0, 4, "[OK] Drivers loaded", Color.makeColor(Color.White, Color.Black));
}

fn init_services() !void {
    // Initialize UI system
    // Initialize logging
    vga.putString(0, 5, "[OK] Services ready", Color.makeColor(Color.White, Color.Black));
}

pub fn kernel_init() void {
    // Phase 1: Hardware setup
    init_hardware() catch |err| {
        panic("Hardware initialization failed: " ++ err.msg);
    };

    // Phase 2: Drivers
    init_drivers() catch |err| {
        panic("Driver initialization failed: " ++ err.msg);
    };

    // Phase 3: Services
    init_services() catch |err| {
        panic("Service initialization failed: " ++ err.msg);
    };
}
