const std = @import("std");
const vga = @import("../drivers/vga.zig");
const Color = @import("../common/types.zig").Color;
const input = @import("input.zig");

// Screen management types
pub const ScreenType = enum { Main, Status, Logs, About };

// Input types
pub const InputType = enum { Command, Text };

// Data storage for screens (reduced for size optimization)
pub var main_output_lines: [25][80]u8 = [_][80]u8{[_]u8{0} ** 80} ** 25;
pub var main_output_count: usize = 0;
pub var main_scroll_offset: usize = 0;

pub var log_lines: [50][80]u8 = [_][80]u8{[_]u8{0} ** 80} ** 50;
pub var log_count: usize = 0;
pub var log_scroll_offset: usize = 0;

// Windows menu popup state
pub var menu_visible: bool = false;
pub var menu_search_buffer: [64]u8 = [_]u8{0} ** 64;
pub var menu_search_length: usize = 0;
pub var menu_search_cursor: usize = 0;

// Screen management
pub var current_screen: ScreenType = .Main;

pub fn switchToScreen(screen: ScreenType) void {
    current_screen = screen;
    input.switchToScreen(screen);
    renderCurrentScreen();
    input.drawInput(current_screen);
}

fn indicatorColor(current: ScreenType, indicator: ScreenType) u8 {
    return if (current == indicator)
        Color.makeColor(Color.Black, Color.Yellow)
    else
        Color.makeColor(Color.White, Color.Magenta);
}

pub fn drawHeader() void {
    // Purple header background (rows 0-4, more compact)
    for (0..5) |row| {
        vga.putStringCentered(row, " " ** vga.VGA_WIDTH, Color.makeColor(Color.White, Color.Magenta)); // White on purple
    }

    // Header content - compact
    vga.putStringCentered(0, "=" ** (vga.VGA_WIDTH), Color.makeColor(Color.Yellow, Color.Magenta));

    vga.putStringCentered(1, "VeigarOS", Color.makeColor(Color.White, Color.Magenta));
    vga.putStringCentered(2, "Interactive v1.0", Color.makeColor(Color.Yellow, Color.Magenta));

    // Screen indicators at bottom of header
    vga.putString(2, 3, "F1:Main", indicatorColor(current_screen, .Main));
    vga.putString(12, 3, "F2:Status", indicatorColor(current_screen, .Status));
    vga.putString(24, 3, "F3:Logs", indicatorColor(current_screen, .Logs));
    vga.putString(34, 3, "F4:About", indicatorColor(current_screen, .About));

    vga.putStringCentered(4, "=" ** (vga.VGA_WIDTH), Color.makeColor(Color.Yellow, Color.Magenta));
}

pub fn renderMainScreen() void {
    // Initial messages
    vga.putString(0, 6, "Type below. Use arrows to scroll.", @intFromEnum(Color.White));
    vga.putString(0, 7, "Press Tab to switch screens.", @intFromEnum(Color.White));
    vga.putString(0, 8, "=" ** vga.VGA_WIDTH, @intFromEnum(Color.DarkGray));

    // Show scrollable output (10 lines visible)
    const start_row = 10;
    const visible_lines = 11; // Lines 10-20 visible
    const max_scroll = if (main_output_count > visible_lines) main_output_count - visible_lines else 0;

    // Ensure scroll offset is valid
    if (main_scroll_offset > max_scroll) {
        main_scroll_offset = max_scroll;
    }

    for (0..visible_lines) |display_idx| {
        const output_idx = main_scroll_offset + display_idx;
        const screen_row = start_row + display_idx;

        if (output_idx < main_output_count and screen_row < 21) { // Don't overlap input area
            const line: []const u8 = std.mem.sliceTo(&main_output_lines[output_idx], 0);
            if (line.len > 0) {
                vga.putString(0, screen_row, line, 0x0F);
            }
        }
    }

    // Show scroll indicator if there are more lines
    if (main_output_count > visible_lines) {
        var scroll_info: [30]u8 = undefined;
        if (std.fmt.bufPrint(scroll_info[0..], "[{d}-{d}/{d}]", .{ main_scroll_offset + 1, @min(main_scroll_offset + visible_lines, main_output_count), main_output_count })) |result| {
            vga.putString(vga.VGA_WIDTH - result.len, 9, result, 0x08); // Dark gray
        } else |_| {}
    }
}

pub fn renderStatusScreen() void {
    vga.putStringCentered(8, "System Status", @intFromEnum(Color.White));
    vga.putString(5, 10, "Kernel: VeigarOS v1.0", @intFromEnum(Color.LightGreen));
    vga.putString(5, 11, "Architecture: x86", @intFromEnum(Color.White));
    vga.putString(5, 12, "Memory: 512MB", @intFromEnum(Color.White));
    vga.putString(5, 13, "Status: Running", @intFromEnum(Color.LightGreen));
    vga.putString(5, 15, "Screens available:", @intFromEnum(Color.Yellow));
    vga.putString(7, 16, "F1: Main Terminal", @intFromEnum(Color.White));
    vga.putString(5, 17, "> F2: System Status", @intFromEnum(Color.White));
    vga.putString(7, 18, "F3: Kernel Logs", @intFromEnum(Color.White));
    vga.putString(7, 19, "F4: About", @intFromEnum(Color.White));
}

pub fn renderLogsScreen() void {
    vga.putStringCentered(6, "Kernel Logs", @intFromEnum(Color.White));
    vga.putString(0, 7, "=" ** vga.VGA_WIDTH, @intFromEnum(Color.DarkGray));
    vga.putString(5, 8, "Use Up/Down arrows to scroll through logs", @intFromEnum(Color.LightGray));

    // Display scrollable logs
    const start_row = 10;
    const visible_lines = 13; // Lines 10-22 visible
    const max_scroll = if (log_count > visible_lines) log_count - visible_lines else 0;

    // Ensure scroll offset is valid
    if (log_scroll_offset > max_scroll) {
        log_scroll_offset = max_scroll;
    }

    for (0..visible_lines) |display_idx| {
        const log_idx = log_scroll_offset + display_idx;
        const screen_row = start_row + display_idx;

        if (log_idx < log_count and screen_row < vga.VGA_HEIGHT - 2) {
            const log_line: []const u8 = std.mem.sliceTo(&log_lines[log_idx], 0);
            if (log_line.len > 0) {
                // Limit display to screen width
                const display_len = @min(log_line.len, vga.VGA_WIDTH);
                vga.putString(0, screen_row, log_line[0..display_len], @intFromEnum(Color.Yellow));
            }
        }
    }

    // Show scroll info
    var info_buffer: [50]u8 = undefined;
    if (log_count > visible_lines) {
        if (std.fmt.bufPrint(info_buffer[0..], "Logs [{d}-{d}/{d}] - Total: {d}/50", .{ log_scroll_offset + 1, @min(log_scroll_offset + visible_lines, log_count), log_count, log_count })) |result| {
            vga.putString(2, vga.VGA_HEIGHT - 1, result, @intFromEnum(Color.DarkGray));
        } else |_| {
            vga.putString(2, vga.VGA_HEIGHT - 1, "Scroll info error", @intFromEnum(Color.DarkGray));
        }
    } else {
        if (std.fmt.bufPrint(info_buffer[0..], "Total logs: {d}/50", .{log_count})) |result| {
            vga.putString(2, vga.VGA_HEIGHT - 1, result, @intFromEnum(Color.DarkGray));
        } else |_| {
            vga.putString(2, vga.VGA_HEIGHT - 1, "Log count error", @intFromEnum(Color.DarkGray));
        }
    }
}

pub fn renderAboutScreen() void {
    vga.putStringCentered(8, "About", @intFromEnum(Color.White));
    vga.putStringCentered(11, "VeigarOS Kernel v1.0", @intFromEnum(Color.LightGray));
    vga.putStringCentered(13, "Built with Zig", @intFromEnum(Color.LightGray));
    vga.putStringCentered(15, "A simple x86 kernel for learning purposes", @intFromEnum(Color.White));

    vga.putStringCentered(19, "Author: Robin (Claude) Romain by contributions", @intFromEnum(Color.DarkGray));
    vga.putStringCentered(20, "Press F1-F4 to navigate", @intFromEnum(Color.Cyan));
}

pub fn renderCurrentScreen() void {
    // Clear screen (keep header)
    var row: usize = 5;
    while (row < vga.VGA_HEIGHT) : (row += 1) {
        var col: usize = 0;
        while (col < vga.VGA_WIDTH) : (col += 1) {
            vga.putChar(col, row, ' ', @intFromEnum(Color.LightGray)); // Clear with default colors
        }
    }

    drawHeader(); // Redraw with updated indicators

    switch (current_screen) {
        .Main => renderMainScreen(),
        .Status => renderStatusScreen(),
        .Logs => renderLogsScreen(),
        .About => renderAboutScreen(),
    }
}

pub fn addLog(message: []const u8) void {
    if (log_count < 50) {
        // Clear the line first
        for (0..log_lines[log_count].len) |i| {
            log_lines[log_count][i] = 0;
        }
        // Copy message with length limit
        const copy_len = @min(message.len, 79);
        @memcpy(log_lines[log_count][0..copy_len], message[0..copy_len]);
        // Ensure null termination
        log_lines[log_count][copy_len] = 0;
        log_count += 1;
    } else {
        // Scroll logs up when buffer is full
        for (1..50) |i| {
            log_lines[i - 1] = log_lines[i];
        }
        // Clear the last line first
        for (0..log_lines[49].len) |i| {
            log_lines[49][i] = 0;
        }
        // Copy message with length limit
        const copy_len = @min(message.len, 79);
        @memcpy(log_lines[49][0..copy_len], message[0..copy_len]);
        // Ensure null termination
        log_lines[49][copy_len] = 0;
    }

    // Auto-scroll to show newest logs (reset scroll when new log added)
    log_scroll_offset = 0;
}

pub fn showWindowsMenu() void {
    menu_visible = true;
    menu_search_length = 0;
    menu_search_cursor = 0;
    for (0..menu_search_buffer.len) |i| {
        menu_search_buffer[i] = 0;
    }
}

pub fn hideWindowsMenu() void {
    menu_visible = false;
}

pub fn drawWindowsMenu() void {
    if (!menu_visible) return;

    // Menu dimensions - centered on screen (4 lines tall)
    const menu_width = 50;
    const menu_height = 4;
    const start_col = (vga.VGA_WIDTH - menu_width) / 2;
    const start_row = (vga.VGA_HEIGHT - menu_height) / 2;

    // Draw 4-line box
    // Top line: /------\
    vga.putChar(start_col, start_row, '/', Color.makeColor(Color.White, Color.Black)); // Top-left corner
    for (1..menu_width - 1) |i| {
        vga.putChar(start_col + i, start_row, '-', Color.makeColor(Color.White, Color.Black)); // Top border
    }
    vga.putChar(start_col + menu_width - 1, start_row, '\\', Color.makeColor(Color.White, Color.Black)); // Top-right corner

    // Second line: | Search: |
    vga.putChar(start_col, start_row + 1, '|', Color.makeColor(Color.White, Color.Black)); // Left border
    // Clear the line
    for (1..menu_width - 1) |i| {
        vga.putChar(start_col + i, start_row + 1, ' ', Color.makeColor(Color.LightGray, Color.Black)); // Background
    }
    // Add "Search:" label
    vga.putString(start_col + 2, start_row + 1, "Search:", Color.makeColor(Color.White, Color.Black));
    vga.putChar(start_col + menu_width - 1, start_row + 1, '|', Color.makeColor(Color.White, Color.Black)); // Right border

    // Third line: |  input field  |
    vga.putChar(start_col, start_row + 2, '|', Color.makeColor(Color.White, Color.Black)); // Left border
    // Clear and draw input field in gray
    const search_start = start_col + 2;
    const search_width = menu_width - 4;
    for (0..search_width) |i| {
        vga.putChar(search_start + i, start_row + 2, ' ', Color.makeColor(Color.Black, Color.LightGray)); // Input field
    }
    vga.putChar(start_col + menu_width - 1, start_row + 2, '|', Color.makeColor(Color.White, Color.Black)); // Right border

    // Display search text in gray input field
    if (menu_search_length > 0) {
        const display_len = @min(menu_search_length, search_width - 1);
        const search_text: []const u8 = menu_search_buffer[0..display_len];
        vga.putString(search_start, start_row + 2, search_text, Color.makeColor(Color.Black, Color.LightGray));
    }

    // Bottom line: \------/
    vga.putChar(start_col, start_row + 3, '\\', Color.makeColor(Color.White, Color.Black)); // Bottom-left corner
    for (1..menu_width - 1) |i| {
        vga.putChar(start_col + i, start_row + 3, '-', Color.makeColor(Color.White, Color.Black)); // Bottom border
    }
    vga.putChar(start_col + menu_width - 1, start_row + 3, '/', Color.makeColor(Color.White, Color.Black)); // Bottom-right corner

    // Position cursor in search box
    const cursor_pos = @min(search_start + menu_search_cursor, search_start + search_width - 1);
    vga.setCursorPosition(cursor_pos, start_row + 2);
}

pub fn setup_ui() void {
    vga.showCursor();
    vga.setCursorPosition(input.PROMPT.len, 23); // Position at input area initially

    renderCurrentScreen(); // This will draw header and main screen
    input.drawInput(current_screen);

    // Add initial logs
    addLog("Kernel started with VeigarOS v1.0");
    addLog("VGA display initialized");
    addLog("Keyboard driver loaded");
    addLog("Multi-screen system active");
    addLog("Press F1-F4 to switch screens");
}
