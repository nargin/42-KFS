const std = @import("std");
const Keyboard = @import("drivers/keyboard.zig").Keyboard;
const keys = @import("common/types.zig").Key;
const Color = @import("common/types.zig").Color;
const vga = @import("drivers/vga.zig");

const screen = @import("ui/screens.zig");
const ScreenType = screen.ScreenType;

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

const keyboard: *Keyboard = null;

fn kmain() void {

    // Initialize kernel subsystems
    init.kernel_init();

    screen.setup_ui();

    // Main loop
    while (true) {
        // TODO: handle_keyboard_interrupt();

        if (keyboard.readScancode()) |key_event| {
            if (key_event.pressed) {
                // Handle F-key screen switching
                const key_code = key_event.scancode & 0x7F;
                switch (key_code) {
                    @intFromEnum(keys.F1) => screen.switchToScreen(.Main),
                    @intFromEnum(keys.F2) => screen.switchToScreen(.Status),
                    @intFromEnum(keys.F3) => screen.switchToScreen(.Logs),
                    @intFromEnum(keys.F4) => screen.switchToScreen(.About),
                    @intFromEnum(keys.Tab) => {
                        // Cycle through screens
                        const next_screen: ScreenType = switch (screen.current_screen) {
                            .Main => .Status,
                            .Status => .Logs,
                            .Logs => .About,
                            .About => .Main,
                        };
                        screen.switchToScreen(next_screen);
                    },
                    else => {
                        // Handle special keys
                        if (key_event.special) |special_key| {
                            switch (special_key) {
                                .WindowsKey => {
                                    screen.showWindowsMenu();
                                    screen.renderCurrentScreen();
                                    input.drawInput();
                                    screen.drawWindowsMenu();
                                },
                                else => {
                                    input.handleArrowKey(special_key, screen.current_screen);
                                    // Re-render screen to show scrolling changes
                                    screen.renderCurrentScreen();
                                    input.drawInput(screen.current_screen);
                                },
                            }
                        }
                        // Handle character input for menu or current screen
                        else {
                            if (key_event.character) |char| {
                                input.handleChar(char);

                                // Redraw everything
                                screen.renderCurrentScreen();
                                input.drawInput(screen.current_screen);
                                screen.drawWindowsMenu(); // Always call this - it checks if menu is visible

                                // Special handling for Main screen input
                                if (char == '\n' and screen.current_screen == .Main and !screen.menu_visible) {
                                    input.processInput(screen.current_screen);
                                    input.drawInput(screen.current_screen);
                                }
                            }
                        }
                    },
                }
            }
        }
    }
}
