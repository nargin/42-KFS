const std = @import("std");
const Keyboard = @import("./keyboard.zig").Keyboard;
const vga = @import("./vga.zig");
const screens = @import("./screens.zig");
const input = @import("./input.zig");

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

var stack_bytes: [16 * 1024]u8 align(16) linksection(".bss") = undefined;

// Screen management
var current_screen: screens.ScreenType = .Main;

fn switchToScreen(screen: screens.ScreenType) void {
    current_screen = screen;
    input.switchToScreen(screen);
    screens.renderCurrentScreen(current_screen);
    input.drawInput(current_screen);
}

export fn _start() callconv(.Naked) noreturn {
    asm volatile (
        \\ movl %[stack_top], %%esp
        \\ movl %%esp, %%ebp
        \\ call %[kmain:P]
        :
        : [stack_top] "i" (@as([*]align(16) u8, @ptrCast(&stack_bytes)) + @sizeOf(@TypeOf(stack_bytes))),
          [kmain] "X" (&kmain),
    );
}

fn kmain() callconv(.C) void {
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
    vga.setCursorPosition(9, 23); // Position at input area initially
    
    screens.renderCurrentScreen(current_screen); // This will draw header and main screen
    input.drawInput(current_screen);

    // Main loop
    while (true) {
        if (keyboard.readScancode()) |key_event| {
            if (key_event.pressed) {
                // Handle F-key screen switching
                const key_code = key_event.scancode & 0x7F;
                switch (key_code) {
                    0x3B => switchToScreen(.Main), // F1
                    0x3C => switchToScreen(.Status), // F2
                    0x3D => switchToScreen(.Logs), // F3
                    0x3E => switchToScreen(.About), // F4
                    else => {
                        // Handle arrow keys
                        if (key_event.special) |special_key| {
                            input.handleArrowKey(special_key, current_screen);
                            // Re-render screen to show scrolling changes
                            screens.renderCurrentScreen(current_screen);
                            input.drawInput(current_screen);
                        }
                        // Handle regular character input (only for Main screen)
                        else if (current_screen == .Main) {
                            if (key_event.character) |char| {
                                if (char == '\n') {
                                    input.processInput(current_screen);
                                    input.drawInput(current_screen); // Redraw input area after processing
                                } else {
                                    input.handleChar(char);
                                    input.drawInput(current_screen); // Redraw input area after each keystroke
                                }
                            }
                        }
                    },
                }
            }
        }
    }
}