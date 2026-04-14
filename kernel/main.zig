const vga = @import("drivers/vga.zig");
const Color = vga.Color;
const Keyboard = @import("drivers/keyboard.zig").Keyboard;
const screen = @import("ui/screens.zig");
const UIContext = @import("ui/context.zig").UIContext;
const input = @import("ui/input.zig");
const panic = @import("panic.zig").panic;
const gdt = @import("arch/x86/gdt.zig");

const ALIGN = 1 << 0;
const MEMINFO = 1 << 1;
const MAGIC = 0x1BADB002;
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

var stack_bytes: [64 * 1024]u8 align(16) linksection(".bss") = undefined;

export fn _start() noreturn {
    asm volatile (
        \\ movl %[stack_top], %%esp
        \\ movl %%esp, %%ebp
        \\ call %[kmain:P]
        :
        : [stack_top] "i" (@as([*]align(16) u8, @ptrCast(&stack_bytes)) + @sizeOf(@TypeOf(stack_bytes))),
          [kmain] "X" (&kmain),
    );
    while (true) {
        asm volatile ("hlt");
    }
}

var keyboard: Keyboard = undefined;
pub var ui_ctx: UIContext = undefined;

fn kernel_init() void {
    gdt.init();
    vga.clearScreen(Color.make(Color.LightGray, Color.Black));
    _ = Keyboard.init() catch |err| {
        panic(err);
    };
}

fn kmain() void {
    kernel_init();

    keyboard = Keyboard.init() catch {
        @panic("Failed to initialize keyboard");
    };
    screen.setup_ui(&ui_ctx);

    while (true) {
        if (keyboard.readScancode()) |key_event| {
            input.handleKeyEvent(&ui_ctx, key_event);
        }
    }
}
