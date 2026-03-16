const vga = @import("drivers/vga.zig");
const Color = @import("common/types.zig").Color;
const Keyboard = @import("drivers/keyboard.zig").Keyboard;
const panic = @import("panic.zig").panic;
const gdt = @import("arch/x86/gdt.zig");
const idt = @import("arch/x86/idt.zig");

fn init_drivers() !void {
    vga.clearScreen(@intFromEnum(Color.LightGray));

    _ = Keyboard.init() catch |err| {
        return err;
    };
}

pub fn kernel_init() void {
    gdt.init();
    // idt.init();

    init_drivers() catch |err| {
        panic(err);
    };
}
