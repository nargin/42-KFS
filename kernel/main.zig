const std = @import("std");
const Keyboard = @import("drivers/keyboard.zig").Keyboard;
const keys = @import("utils/types.zig").Key;
const Color = @import("utils/types.zig").Color;
const vga = @import("drivers/vga.zig");
const screens = @import("lib/screens.zig");
const input = @import("lib/input.zig");

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

// Screen management
var current_screen: screens.ScreenType = .Main;

fn switchToScreen(screen: screens.ScreenType) void {
    current_screen = screen;
    input.switchToScreen(screen);
    screens.renderCurrentScreen(current_screen);
    input.drawInput(current_screen);
}

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

fn kmain() void {
    var keyboard = Keyboard.init();

    // Add initial logs
    screens.addLog("Kernel started with VeigarOS v1.0");
    screens.addLog("VGA display initialized");
    screens.addLog("Keyboard driver loaded");
    screens.addLog("Multi-screen system active");
    screens.addLog("Press F1-F4 to switch screens");

    // Initialize display
    vga.clearScreen(0x07); // Light gray on black

    // Set up hardware cursor
    vga.showCursor();
    vga.setCursorPosition(input.PROMPT.len, 23); // Position at input area initially

    screens.renderCurrentScreen(current_screen); // This will draw header and main screen
    input.drawInput(current_screen);

    // Main loop
    while (true) {
        if (keyboard.readScancode()) |key_event| {
            if (key_event.pressed) {
                // Handle F-key screen switching
                const key_code = key_event.scancode & 0x7F;
                switch (key_code) {
                    @intFromEnum(keys.F1) => switchToScreen(.Main),
                    @intFromEnum(keys.F2) => switchToScreen(.Status),
                    @intFromEnum(keys.F3) => switchToScreen(.Logs),
                    @intFromEnum(keys.F4) => switchToScreen(.About),
                    @intFromEnum(keys.Tab) => {
                        // Cycle through screens
                        const next_screen: screens.ScreenType = switch (current_screen) {
                            .Main => .Status,
                            .Status => .Logs,
                            .Logs => .About,
                            .About => .Main,
                        };
                        switchToScreen(next_screen);
                    },
                    else => {
                        // Handle special keys
                        if (key_event.special) |special_key| {
                            switch (special_key) {
                                .WindowsKey => {
                                    screens.showWindowsMenu();
                                    screens.renderCurrentScreen(current_screen);
                                    input.drawInput(current_screen);
                                    screens.drawWindowsMenu();
                                },
                                else => {
                                    input.handleArrowKey(special_key, current_screen);
                                    // Re-render screen to show scrolling changes
                                    screens.renderCurrentScreen(current_screen);
                                    input.drawInput(current_screen);
                                },
                            }
                        }
                        // Handle character input for menu or current screen
                        else {
                            if (key_event.character) |char| {
                                input.handleChar(char);

                                // Redraw everything
                                screens.renderCurrentScreen(current_screen);
                                input.drawInput(current_screen);
                                screens.drawWindowsMenu(); // Always call this - it checks if menu is visible

                                // Special handling for Main screen input
                                if (char == '\n' and current_screen == .Main and !screens.menu_visible) {
                                    input.processInput(current_screen);
                                    input.drawInput(current_screen);
                                }
                            }
                        }
                    },
                }
            }
        }
    }
}
