const std = @import("std");
const vga = @import("drivers/vga.zig");
const Color = @import("common/types.zig").Color;
const Keyboard = @import("drivers/keyboard.zig").Keyboard;
const panic = @import("panic.zig").panic;
const screens = @import("ui/screens.zig");

fn init_hardware() void {
    // Initialize hardware components if needed
}

fn init_drivers() !void {
    // Initialize keyboard
    // Initialize other drivers
    vga.clearScreen(0x07); // Clear screen with black background and light gray text

    _ = Keyboard.init() catch |err| {
        return err;
    };
}

fn init_services() !void {
    // Initialize UI system
    // Initialize logging
}

pub fn kernel_init() void {
    // Phase 1: Drivers
    init_drivers() catch |err| {
        panic("Driver initialization failed: " ++ err.msg);
    };

    // Phase 2: Services
    init_services() catch |err| {
        panic("Service initialization failed: " ++ err.msg);
    };
}
