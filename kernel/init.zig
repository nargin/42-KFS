const std = @import("std");
const vga = @import("drivers/vga.zig");
const Color = @import("common/types.zig").Color;
const Keyboard = @import("drivers/keyboard.zig").Keyboard;
const panic = @import("panic.zig").panic;
const screens = @import("ui/screens.zig");

fn init_drivers() !void {
    vga.clearScreen(@intFromEnum(Color.LightGray));

    _ = Keyboard.init() catch |err| {
        return err;
    };
}

pub fn kernel_init() void {
    init_drivers() catch |err| {
        panic(err);
    };
}
