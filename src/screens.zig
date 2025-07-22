const std = @import("std");
const vga = @import("./vga.zig");

// Screen management types
pub const ScreenType = enum { Main, Status, Logs, About };

// Data storage for screens (reduced for size optimization)
pub var main_output_lines: [25][80]u8 = [_][80]u8{[_]u8{0} ** 80} ** 25;
pub var main_output_count: usize = 0;
pub var main_scroll_offset: usize = 0;

pub var log_lines: [50][80]u8 = [_][80]u8{[_]u8{0} ** 80} ** 50;
pub var log_count: usize = 0;
pub var log_scroll_offset: usize = 0;

pub fn drawHeader(current_screen: ScreenType) void {
    // Purple header background (rows 0-4, more compact)
    var row: usize = 0;
    while (row < 5) : (row += 1) {
        var col: usize = 0;
        while (col < vga.VGA_WIDTH) : (col += 1) {
            vga.putChar(col, row, ' ', 0x5F); // White on purple
        }
    }

    // Header content - compact
    var i: usize = 0;
    while (i < vga.VGA_WIDTH) : (i += 1) { vga.putChar(i, 0, '=', 0x5E); }
    vga.putString(32, 1, "VeigarOS", 0x5F); // White on purple (centered)
    vga.putString(29, 2, "Interactive v1.0", 0x5E); // Yellow on purple (centered)

    // Screen indicators at bottom of header
    vga.putString(2, 3, "F1:Main", if (current_screen == .Main) 0x5C else 0x58);
    vga.putString(12, 3, "F2:Status", if (current_screen == .Status) 0x5C else 0x58);
    vga.putString(24, 3, "F3:Logs", if (current_screen == .Logs) 0x5C else 0x58);
    vga.putString(34, 3, "F4:About", if (current_screen == .About) 0x5C else 0x58);

    i = 0; while (i < vga.VGA_WIDTH) : (i += 1) { vga.putChar(i, 4, '=', 0x5E); }
}

pub fn renderMainScreen() void {
    // Initial messages
    vga.putString(5, 6, "Kernel started!", 0x0A); // Green on black
    vga.putString(5, 7, "Keyboard enabled.", 0x0F); // White on black
    vga.putString(5, 8, "Type below. Use arrows to scroll.", 0x0F); // White on black

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
    vga.putString(30, 8, "System Status", 0x0F);
    vga.putString(5, 10, "Kernel: VeigarOS v1.0", 0x0A);
    vga.putString(5, 11, "Architecture: x86", 0x0F);
    vga.putString(5, 12, "Memory: 512MB", 0x0F);
    vga.putString(5, 13, "Status: Running", 0x0A);
    vga.putString(5, 15, "Screens available:", 0x0E);
    vga.putString(7, 16, "F1: Main Terminal", 0x0F);
    vga.putString(7, 17, "F2: System Status", 0x0F);
    vga.putString(7, 18, "F3: Kernel Logs", 0x0F);
    vga.putString(7, 19, "F4: About", 0x0F);
}

pub fn renderLogsScreen() void {
    vga.putString(32, 6, "Kernel Logs", 0x0F);
    vga.putString(0, 7, "=" ** vga.VGA_WIDTH, 0x08); // Dark gray separator
    vga.putString(5, 8, "Use Up/Down arrows to scroll through logs", 0x07);
    
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
                vga.putString(0, screen_row, log_line[0..display_len], 0x0E); // Yellow logs
            }
        }
    }
    
    // Show scroll info
    var info_buffer: [50]u8 = undefined;
    if (log_count > visible_lines) {
        if (std.fmt.bufPrint(info_buffer[0..], "Logs [{d}-{d}/{d}] - Total: {d}/50", .{ log_scroll_offset + 1, @min(log_scroll_offset + visible_lines, log_count), log_count, log_count })) |result| {
            vga.putString(2, vga.VGA_HEIGHT - 1, result, 0x08); // Dark gray
        } else |_| {
            vga.putString(2, vga.VGA_HEIGHT - 1, "Scroll info error", 0x08);
        }
    } else {
        if (std.fmt.bufPrint(info_buffer[0..], "Total logs: {d}/50", .{log_count})) |result| {
            vga.putString(2, vga.VGA_HEIGHT - 1, result, 0x08); // Dark gray
        } else |_| {
            vga.putString(2, vga.VGA_HEIGHT - 1, "Log count error", 0x08);
        }
    }
}

pub fn renderAboutScreen() void {
    vga.putString(35, 8, "About", 0x0F);
    vga.putString(25, 11, "VeigarOS Kernel v1.0", 0x0E);
    vga.putString(30, 13, "Built with Zig", 0x07);
    vga.putString(20, 15, "A simple x86 kernel for learning", 0x0F);
    vga.putString(28, 16, "purposes and fun!", 0x0F);

    vga.putString(15, 19, "Author: Robin (Claude) Romain by contributions", 0x08);
    vga.putString(25, 20, "Press F1-F4 to navigate", 0x0C);
}

pub fn renderCurrentScreen(current_screen: ScreenType) void {
    // Clear screen (keep header)
    var row: usize = 5;
    while (row < vga.VGA_HEIGHT) : (row += 1) {
        var col: usize = 0;
        while (col < vga.VGA_WIDTH) : (col += 1) {
            vga.putChar(col, row, ' ', 0x07); // Clear with default colors
        }
    }

    drawHeader(current_screen); // Redraw with updated indicators

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