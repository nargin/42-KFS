const std = @import("std");
const Keyboard = @import("drivers/keyboard.zig").Keyboard;
const keys = @import("common/types.zig").Key;
const Color = @import("common/types.zig").Color;
const vga = @import("drivers/vga.zig");

const screen = @import("ui/screens.zig");
const UIContext = @import("ui/context.zig").UIContext;

const panic = @import("panic.zig").panic;
const input = @import("ui/input.zig");
const init = @import("init.zig");

const ALIGN = 1 << 0;
const MEMINFO = 1 << 1;
const MAGIC = 0x1BADB002; // Multiboot magic number
const FLAGS = ALIGN | MEMINFO;

const MultibootHeader = packed struct {
    magic: i32 = MAGIC,
    flags: i32,
    checksum: i32,
    padding: u32 = 0,
};

export var multiboot: MultibootHeader align(4) linksection(".multiboot") = .{
    .flags = FLAGS,
    .checksum = -(MAGIC + FLAGS),
};

var stack_bytes: [16 * 1024]u8 align(16) linksection(".bss") = undefined;

export fn _start() noreturn {
    asm volatile (
        \\ movl %[stack_top], %%esp
        \\ movl %%esp, %%ebp
        \\ call %[kmain:P]
        :
        : [stack_top] "i" (@as([*]align(16) u8, @ptrCast(&stack_bytes)) + @sizeOf(@TypeOf(stack_bytes))),
          [kmain] "X" (&kmain),
    );

    // If kmain ever returns, halt the system
    while (true) {
        asm volatile ("hlt");
    }
}

var keyboard: Keyboard = undefined;
var ui_ctx: UIContext = undefined;

fn kmain() void {
    // Initialize kernel subsystems
    init.kernel_init();

    // Initialize UI context
    ui_ctx = UIContext.init();
    ui_ctx.initViews();

    // Initialize input subsystem
    input.initHostname();

    // Initialize keyboard at runtime
    keyboard = Keyboard.init() catch {
        @panic("Failed to initialize keyboard");
    };
    screen.setup_ui(&ui_ctx);

    // Main loop - simple polling for now
    while (true) {
        if (keyboard.readScancode()) |key_event| {
            input.handleKeyEvent(&ui_ctx, key_event);
        }
    }
}
