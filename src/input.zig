const std = @import("std");
const vga = @import("./vga.zig");
const screens = @import("./screens.zig");
const ScreenType = screens.ScreenType;
const SpecialKey = @import("./keyboard/keyboard.zig").SpecialKey;

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

pub fn drawInput(current_screen: ScreenType) void {
    // Only draw input for Main screen
    if (current_screen != .Main) return;

    // Input area
    vga.putString(0, 22, "=" ** vga.VGA_WIDTH, 0x1E); // Yellow on blue
    vga.putString(0, 23, PROMPT, 0x0B); // Cyan on black

    // Clear input line from position 9 onwards
    var col: usize = PROMPT.len;
    while (col < vga.VGA_WIDTH) : (col += 1) {
        vga.putChar(col, 23, ' ', 0x07); // Clear with default colors
    }

    // Display current input (limit to screen width)
    if (input_length.* > 0) {
        const max_display_chars = vga.VGA_WIDTH - PROMPT.len; // 71 characters max
        const display_len = @min(input_length.*, max_display_chars);
        const display_text = input_buffer.*[0..display_len];
        vga.putString(PROMPT.len, 23, display_text, 0x0F); // White on black
    }

    // Update hardware cursor position for Main screen (if visible)

    if (current_screen == .Main) {
        const cursor_pos = @min(PROMPT.len + input_cursor.*, vga.VGA_WIDTH - 1);
        vga.setCursorPosition(cursor_pos, 23);
    }
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
    if (char == 27) { // ESC
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
        0x08 => { // Backspace
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
        '\n' => { // Enter
            // processInput() will be called from main loop
        },
        else => {
            const max_input_chars = vga.VGA_WIDTH - 9; // 71 characters max to fit on screen
            if (char >= 32 and char <= 126 and input_length.* < @min(255, max_input_chars)) {
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
        },
    }
}

pub fn handleMenuChar(char: u8) void {
    switch (char) {
        0x08 => { // Backspace in menu search
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
        '\n' => { // Enter in menu - could select item or search
            // For now, just close menu
            screens.hideWindowsMenu();
        },
        else => {
            const max_search_chars = 60;
            if (char >= 32 and char <= 126 and screens.menu_search_length < @min(63, max_search_chars)) {
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
                .WindowsKey => {
                    // Handled in main loop
                },
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
                .ArrowLeft, .ArrowRight => {
                    // No horizontal scrolling in logs
                },
                .WindowsKey => {
                    // Handled in main loop
                },
            }
        },
        .Status, .About => {
            // No scrolling on status/about screens
        },
    }
}

pub fn switchToScreen(screen: ScreenType) void {
    // Update pointers to correct screen data
    switch (screen) {
        .Main => {
            input_buffer = &main_input_buffer;
            input_length = &main_input_length;
            input_cursor = &main_input_cursor;
            output_row = &main_output_row;
        },
        else => {
            // Other screens don't have input for now
            input_buffer = &main_input_buffer; // Fallback
            input_length = &main_input_length;
            input_cursor = &main_input_cursor;
            output_row = &main_output_row;
        },
    }

    // Handle cursor visibility based on current screen
    if (screen == .Main) {
        vga.showCursor();
        vga.setCursorPosition(9 + input_cursor.*, 23);
    } else {
        vga.hideCursor();
    }
}
