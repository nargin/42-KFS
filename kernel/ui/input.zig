const std = @import("std");
const vga = @import("../drivers/vga.zig");
const screens = @import("./screens.zig");
const ScreenType = screens.ScreenType;
const SpecialKey = @import("../common/types.zig").SpecialKey;
const Key = @import("../common/types.zig").Key;
const ASCII = @import("../common/types.zig").ASCII;

// Input state
pub var main_input_buffer: [256]u8 = [_]u8{0} ** 256;
pub var main_input_length: usize = 0;
pub var main_input_cursor: usize = 0;
pub var main_output_row: usize = 12;

// Current active pointers (point to current screen's data)
pub var input_buffer: *[256]u8 = &main_input_buffer;
pub var input_length: *usize = &main_input_length;
pub var input_cursor: *usize = &main_input_cursor;
pub var output_row: *usize = &main_output_row;

pub const PROMPT: []const u8 = "> Input: ";

// Display constants
const INPUT_ROW = 23;
const SEPARATOR_ROW = 22;
const MAX_INPUT_BUFFER_SIZE = 255;
const MAX_MENU_SEARCH_SIZE = 63;
const MENU_SEARCH_DISPLAY_WIDTH = 60;

pub fn drawInput(current_screen: ScreenType) void {
    // Only draw input for Main screen
    if (current_screen != .Main) return;

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
    if (input_length.* > 0) {
        const available_width = vga.VGA_WIDTH - PROMPT.len;
        const display_len = @min(input_length.*, available_width);
        const display_text = input_buffer.*[0..display_len];
        vga.putString(PROMPT.len, INPUT_ROW, display_text, 0x0F); // White on black
    }

    // Position hardware cursor at input position
    const cursor_pos = @min(PROMPT.len + input_cursor.*, vga.VGA_WIDTH - 1);
    vga.setCursorPosition(cursor_pos, INPUT_ROW);
}

pub fn processInput(current_screen: ScreenType) void {
    if (input_length.* == 0) return;

    // Create a log message with the user input
    var log_buffer: [80]u8 = [_]u8{0} ** 80;
    const log_prefix = "USER: ";
    @memcpy(log_buffer[0..log_prefix.len], log_prefix);
    const copy_len = @min(input_length.*, 80 - log_prefix.len - 1);
    @memcpy(log_buffer[log_prefix.len .. log_prefix.len + copy_len], input_buffer.*[0..copy_len]);
    screens.addLog(log_buffer[0 .. log_prefix.len + copy_len]);

    // Save to persistent output lines for main screen
    if (current_screen == .Main) {
        if (screens.main_output_count < 25) {
            const prefix = "> ";
            @memcpy(screens.main_output_lines[screens.main_output_count][0..prefix.len], prefix);
            @memcpy(screens.main_output_lines[screens.main_output_count][prefix.len .. prefix.len + input_length.*], input_buffer.*[0..input_length.*]);
            screens.main_output_count += 1;
        } else {
            // Scroll main output up when buffer is full
            for (1..25) |i| {
                screens.main_output_lines[i - 1] = screens.main_output_lines[i];
            }
            const prefix = "> ";
            @memcpy(screens.main_output_lines[24][0..prefix.len], prefix);
            @memcpy(screens.main_output_lines[24][prefix.len .. prefix.len + input_length.*], input_buffer.*[0..input_length.*]);
        }

        // Reset scroll offset to show newest output
        screens.main_scroll_offset = 0;
    }

    // Clear input buffer
    input_length.* = 0;
    input_cursor.* = 0; // Reset cursor position
    for (0..input_buffer.*.len) |i| {
        input_buffer.*[i] = 0;
    }

    // Re-render to show the new output
    if (current_screen == .Main) {
        screens.renderMainScreen();
    }
}

pub fn handleChar(char: u8) void {
    // Handle ESC key to close Windows menu
    if (char == ASCII.ESCAPE) {
        if (screens.menu_visible) {
            screens.hideWindowsMenu();
            return;
        }
    }

    // If Windows menu is visible, handle menu input
    if (screens.menu_visible) {
        handleMenuChar(char);
        return;
    }

    switch (char) {
        ASCII.BACKSPACE => {
            if (input_cursor.* > 0) {
                // Move cursor left and delete character
                input_cursor.* -= 1;
                // Shift characters left
                for (input_cursor.*..input_length.* - 1) |i| {
                    input_buffer.*[i] = input_buffer.*[i + 1];
                }
                input_length.* -= 1;
                input_buffer.*[input_length.*] = 0;
            }
        },
        ASCII.ENTER => {
            // processInput() will be called from main loop
        },
        else => {
            const available_input_chars = vga.VGA_WIDTH - PROMPT.len;
            const max_chars = @min(MAX_INPUT_BUFFER_SIZE, available_input_chars);

            if (ASCII.isPrintable(char) and input_length.* < max_chars) {
                insertCharAtCursor(char);
            }
        },
    }
}

pub fn handleMenuChar(char: u8) void {
    switch (char) {
        ASCII.BACKSPACE => { // Backspace in menu search
            if (screens.menu_search_cursor > 0) {
                screens.menu_search_cursor -= 1;
                // Shift characters left
                for (screens.menu_search_cursor..screens.menu_search_length - 1) |i| {
                    screens.menu_search_buffer[i] = screens.menu_search_buffer[i + 1];
                }
                screens.menu_search_length -= 1;
                screens.menu_search_buffer[screens.menu_search_length] = 0;
            }
        },
        ASCII.ENTER => {
            // For now, just close menu when Enter is pressed
            screens.hideWindowsMenu();
        },
        else => {
            const max_chars = @min(MAX_MENU_SEARCH_SIZE, MENU_SEARCH_DISPLAY_WIDTH);
            if (ASCII.isPrintable(char) and screens.menu_search_length < max_chars) {
                insertCharInMenuSearch(char);
            }
        },
    }
}

pub fn handleArrowKey(arrow_key: SpecialKey, current_screen: ScreenType) void {
    switch (current_screen) {
        .Main => {
            switch (arrow_key) {
                .ArrowLeft => {
                    if (input_cursor.* > 0) {
                        input_cursor.* -= 1;
                    }
                },
                .ArrowRight => {
                    if (input_cursor.* < input_length.*) {
                        input_cursor.* += 1;
                    }
                },
                .ArrowUp => {
                    // Scroll up in main output
                    const visible_lines = 11;
                    const max_scroll = if (screens.main_output_count > visible_lines) screens.main_output_count - visible_lines else 0;
                    if (screens.main_scroll_offset < max_scroll) {
                        screens.main_scroll_offset += 1;
                    }
                },
                .ArrowDown => {
                    // Scroll down in main output
                    if (screens.main_scroll_offset > 0) {
                        screens.main_scroll_offset -= 1;
                    }
                },
                else => {},
            }
        },
        .Logs => {
            switch (arrow_key) {
                .ArrowUp => {
                    // Scroll up in logs
                    const visible_lines = 13;
                    const max_scroll = if (screens.log_count > visible_lines) screens.log_count - visible_lines else 0;
                    if (screens.log_scroll_offset < max_scroll) {
                        screens.log_scroll_offset += 1;
                    }
                },
                .ArrowDown => {
                    // Scroll down in logs
                    if (screens.log_scroll_offset > 0) {
                        screens.log_scroll_offset -= 1;
                    }
                },
                else => {},
            }
        },
        .Status, .About => {
            // No scrolling on status/about screens
        },
    }
}

// Helper function to insert character at cursor position in main input
fn insertCharAtCursor(char: u8) void {
    // Shift characters right to make room for new character
    if (input_cursor.* < input_length.*) {
        var i = input_length.*;
        while (i > input_cursor.*) {
            input_buffer.*[i] = input_buffer.*[i - 1];
            i -= 1;
        }
    }
    // Insert new character at cursor position
    input_buffer.*[input_cursor.*] = char;
    input_length.* += 1;
    input_cursor.* += 1;
}

// Helper function to insert character in menu search
fn insertCharInMenuSearch(char: u8) void {
    // Shift characters right to make room for new character
    if (screens.menu_search_cursor < screens.menu_search_length) {
        var i = screens.menu_search_length;
        while (i > screens.menu_search_cursor) {
            screens.menu_search_buffer[i] = screens.menu_search_buffer[i - 1];
            i -= 1;
        }
    }
    // Insert new character at cursor position
    screens.menu_search_buffer[screens.menu_search_cursor] = char;
    screens.menu_search_length += 1;
    screens.menu_search_cursor += 1;
}

pub fn switchToScreen(screen: ScreenType) void {
    // Update pointers to correct screen data
    input_buffer = &main_input_buffer;
    input_length = &main_input_length;
    input_cursor = &main_input_cursor;
    output_row = &main_output_row;

    // Handle cursor visibility based on current screen
    if (screen == .Main) {
        vga.showCursor();
        vga.setCursorPosition(PROMPT.len + input_cursor.*, INPUT_ROW);
    } else {
        vga.hideCursor();
    }
}

// Central keyboard event dispatcher
pub fn handleKeyEvent(key_event: anytype, current_screen: ScreenType) void {
    if (!key_event.pressed) return;

    const key_code = key_event.scancode & 0x7F;

    // Handle F-keys for screen switching
    switch (key_code) {
        @intFromEnum(Key.F1) => {
            screens.switchToScreen(.Main);
            return;
        },
        @intFromEnum(Key.F2) => {
            screens.switchToScreen(.Status);
            return;
        },
        @intFromEnum(Key.F3) => {
            screens.switchToScreen(.Logs);
            return;
        },
        @intFromEnum(Key.F4) => {
            screens.switchToScreen(.About);
            return;
        },
        @intFromEnum(Key.Tab) => {
            // Cycle through screens
            const next_screen: ScreenType = switch (current_screen) {
                .Main => .Status,
                .Status => .Logs,
                .Logs => .About,
                .About => .Main,
            };
            screens.switchToScreen(next_screen);
            return;
        },
        else => {},
    }

    // Handle special keys (arrows, Windows key, etc.)
    if (key_event.special) |special_key| {
        switch (special_key) {
            .WindowsKey => {
                screens.showWindowsMenu();
                screens.renderCurrentScreen();
                drawInput(current_screen);
                screens.drawWindowsMenu();
            },
            else => {
                handleArrowKey(special_key, current_screen);
                screens.renderCurrentScreen();
                drawInput(current_screen);
            },
        }
        return;
    }

    // Handle character input
    if (key_event.character) |char| {
        handleChar(char);

        // Redraw everything
        screens.renderCurrentScreen();
        drawInput(current_screen);
        screens.drawWindowsMenu();

        // Process input on Enter for Main screen
        if (char == '\n' and current_screen == .Main and !screens.menu_visible) {
            processInput(current_screen);
            drawInput(current_screen);
        }
    }
}
