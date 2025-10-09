const std = @import("std");
const vga = @import("../drivers/vga.zig");
const screens = @import("./screens.zig");
const UIContext = @import("context.zig").UIContext;
const ScreenType = @import("context.zig").ScreenType;
const SpecialKey = @import("../common/types.zig").SpecialKey;
const Key = @import("../common/types.zig").Key;
const ASCII = @import("../common/types.zig").ASCII;

pub const PROMPT: []const u8 = "> Input: ";

// Display constants
const INPUT_ROW = 23;
const SEPARATOR_ROW = 22;
const MAX_INPUT_BUFFER_SIZE = 255;
const MAX_MENU_SEARCH_SIZE = 63;
const MENU_SEARCH_DISPLAY_WIDTH = 60;

pub fn drawInput(ctx: *UIContext) void {
    // Only draw input for Main screen
    if (ctx.current_screen != .Main) return;

    // Draw input separator line
    vga.putString(0, SEPARATOR_ROW, "=" ** vga.VGA_WIDTH, 0x1E); // Yellow on blue

    // Draw input prompt
    vga.putString(0, INPUT_ROW, PROMPT, 0x0B); // Cyan on black

    // Clear input line after prompt
    var col: usize = PROMPT.len;
    while (col < vga.VGA_WIDTH) : (col += 1) {
        vga.putChar(col, INPUT_ROW, ' ', 0x07); // Clear with default colors
    }

    // Display current input text (limit to available screen width)
    if (ctx.main_input.length > 0) {
        const available_width = vga.VGA_WIDTH - PROMPT.len;
        const display_len = @min(ctx.main_input.length, available_width);
        const display_text = ctx.main_input.data[0..display_len];
        vga.putString(PROMPT.len, INPUT_ROW, display_text, 0x0F); // White on black
    }

    // Position hardware cursor at input position
    const cursor_pos = @min(PROMPT.len + ctx.main_input.cursor, vga.VGA_WIDTH - 1);
    vga.setCursorPosition(cursor_pos, INPUT_ROW);
}

pub fn processInput(ctx: *UIContext) void {
    if (ctx.main_input.length == 0) return;

    // Create a log message with the user input
    var log_buffer: [80]u8 = [_]u8{0} ** 80;
    const log_prefix = "USER: ";
    @memcpy(log_buffer[0..log_prefix.len], log_prefix);
    const copy_len = @min(ctx.main_input.length, 80 - log_prefix.len - 1);
    @memcpy(log_buffer[log_prefix.len .. log_prefix.len + copy_len], ctx.main_input.data[0..copy_len]);
    screens.addLog(ctx, log_buffer[0 .. log_prefix.len + copy_len]);

    // Save to persistent output lines for main screen
    if (ctx.current_screen == .Main) {
        var output_line: [80]u8 = [_]u8{0} ** 80;
        const prefix = "> ";
        @memcpy(output_line[0..prefix.len], prefix);
        @memcpy(output_line[prefix.len .. prefix.len + ctx.main_input.length], ctx.main_input.data[0..ctx.main_input.length]);
        ctx.main_output.addLine(&output_line);
    }

    // Clear input buffer
    ctx.main_input.clear();

    // Re-render to show the new output
    if (ctx.current_screen == .Main) {
        screens.renderMainScreen(ctx);
    }
}

pub fn handleChar(ctx: *UIContext, char: u8) void {
    // Handle ESC key to close Windows menu
    if (char == ASCII.ESCAPE) {
        if (ctx.menu_visible) {
            screens.hideWindowsMenu(ctx);
            return;
        }
    }

    // If Windows menu is visible, handle menu input
    if (ctx.menu_visible) {
        handleMenuChar(ctx, char);
        return;
    }

    switch (char) {
        ASCII.BACKSPACE => {
            ctx.main_input.deleteChar();
        },
        ASCII.ENTER => {
            // processInput() will be called from main loop
        },
        else => {
            const available_input_chars = vga.VGA_WIDTH - PROMPT.len;
            const max_chars = @min(MAX_INPUT_BUFFER_SIZE, available_input_chars);

            if (ASCII.isPrintable(char)) {
                ctx.main_input.insertChar(char, max_chars);
            }
        },
    }
}

pub fn handleMenuChar(ctx: *UIContext, char: u8) void {
    switch (char) {
        ASCII.BACKSPACE => {
            ctx.menu_search.deleteChar();
        },
        ASCII.ENTER => {
            screens.hideWindowsMenu(ctx);
        },
        else => {
            const max_chars = @min(MAX_MENU_SEARCH_SIZE, MENU_SEARCH_DISPLAY_WIDTH);
            if (ASCII.isPrintable(char)) {
                ctx.menu_search.insertChar(char, max_chars);
            }
        },
    }
}

pub fn handleArrowKey(ctx: *UIContext, arrow_key: SpecialKey) void {
    switch (ctx.current_screen) {
        .Main => {
            switch (arrow_key) {
                .ArrowLeft => {
                    if (ctx.main_input.cursor > 0) {
                        ctx.main_input.cursor -= 1;
                    }
                },
                .ArrowRight => {
                    if (ctx.main_input.cursor < ctx.main_input.length) {
                        ctx.main_input.cursor += 1;
                    }
                },
                .ArrowUp => {
                    ctx.main_output.scrollUp(11);
                },
                .ArrowDown => {
                    ctx.main_output.scrollDown();
                },
                else => {},
            }
        },
        .Logs => {
            switch (arrow_key) {
                .ArrowUp => {
                    ctx.logs.scrollUp(13);
                },
                .ArrowDown => {
                    ctx.logs.scrollDown();
                },
                else => {},
            }
        },
        .Status, .About => {
            // No scrolling on status/about screens
        },
    }
}

pub fn switchToScreen(ctx: *UIContext, screen: ScreenType) void {
    _ = screen;
    // Handle cursor visibility based on current screen
    if (ctx.current_screen == .Main) {
        vga.showCursor();
        vga.setCursorPosition(PROMPT.len + ctx.main_input.cursor, INPUT_ROW);
    } else {
        vga.hideCursor();
    }
}

// Central keyboard event dispatcher
pub fn handleKeyEvent(ctx: *UIContext, key_event: anytype) void {
    if (!key_event.pressed) return;

    const key_code = key_event.scancode & 0x7F;

    // Handle F-keys for screen switching
    switch (key_code) {
        @intFromEnum(Key.F1) => {
            screens.switchToScreen(ctx, .Main);
            return;
        },
        @intFromEnum(Key.F2) => {
            screens.switchToScreen(ctx, .Status);
            return;
        },
        @intFromEnum(Key.F3) => {
            screens.switchToScreen(ctx, .Logs);
            return;
        },
        @intFromEnum(Key.F4) => {
            screens.switchToScreen(ctx, .About);
            return;
        },
        @intFromEnum(Key.Tab) => {
            // Cycle through screens
            const next_screen: ScreenType = switch (ctx.current_screen) {
                .Main => .Status,
                .Status => .Logs,
                .Logs => .About,
                .About => .Main,
            };
            screens.switchToScreen(ctx, next_screen);
            return;
        },
        else => {},
    }

    // Handle special keys (arrows, Windows key, etc.)
    if (key_event.special) |special_key| {
        switch (special_key) {
            .WindowsKey => {
                screens.showWindowsMenu(ctx);
                screens.renderCurrentScreen(ctx);
                drawInput(ctx);
                screens.drawWindowsMenu(ctx);
            },
            else => {
                handleArrowKey(ctx, special_key);
                screens.renderCurrentScreen(ctx);
                drawInput(ctx);
            },
        }
        return;
    }

    // Handle character input
    if (key_event.character) |char| {
        handleChar(ctx, char);

        // Redraw everything
        screens.renderCurrentScreen(ctx);
        drawInput(ctx);
        screens.drawWindowsMenu(ctx);

        // Process input on Enter for Main screen
        if (char == '\n' and ctx.current_screen == .Main and !ctx.menu_visible) {
            processInput(ctx);
            drawInput(ctx);
        }
    }
}
