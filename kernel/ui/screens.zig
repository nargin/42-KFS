const std = @import("std");
const vga = @import("../drivers/vga.zig");
const Color = @import("../common/types.zig").Color;
const input = @import("input.zig");
const UIContext = @import("context.zig").UIContext;
pub const ScreenType = @import("context.zig").ScreenType;

pub fn switchToScreen(ctx: *UIContext, screen: ScreenType) void {
    ctx.current_screen = screen;
    input.switchToScreen(ctx, screen);
    renderCurrentScreen(ctx);
    input.drawInput(ctx);
}

fn indicatorColor(ctx: *const UIContext, indicator: ScreenType) u8 {
    return if (ctx.current_screen == indicator)
        Color.makeColor(Color.Black, Color.Yellow)
    else
        Color.makeColor(Color.White, Color.Magenta);
}

pub fn drawHeader(ctx: *const UIContext) void {
    // Purple header background (rows 0-4, more compact)
    for (0..5) |row| {
        vga.putStringCentered(row, " " ** vga.VGA_WIDTH, Color.makeColor(Color.White, Color.Magenta)); // White on purple
    }

    // Header content - compact
    vga.putStringCentered(0, "=" ** (vga.VGA_WIDTH), Color.makeColor(Color.Yellow, Color.Magenta));

    vga.putStringCentered(1, "VeigarOS", Color.makeColor(Color.White, Color.Magenta));
    vga.putStringCentered(2, "Interactive v1.0", Color.makeColor(Color.Yellow, Color.Magenta));

    // Screen indicators at bottom of header
    vga.putString(2, 3, "F1:Main", indicatorColor(ctx, .Main));
    vga.putString(12, 3, "F2:Status", indicatorColor(ctx, .Status));
    vga.putString(24, 3, "F3:Logs", indicatorColor(ctx, .Logs));
    vga.putString(34, 3, "F4:About", indicatorColor(ctx, .About));

    vga.putStringCentered(4, "=" ** (vga.VGA_WIDTH), Color.makeColor(Color.Yellow, Color.Magenta));
}

pub fn renderMainScreen(ctx: *UIContext) void {
    // Initial messages
    vga.putString(0, 6, "Type below. Use arrows to scroll.", @intFromEnum(Color.White));
    vga.putString(0, 7, "Press Tab to switch screens.", @intFromEnum(Color.White));
    vga.putString(0, 8, "=" ** vga.VGA_WIDTH, @intFromEnum(Color.DarkGray));

    // Show scrollable output (10 lines visible)
    const start_row = 10;
    const visible_lines = 11; // Lines 10-20 visible
    const max_scroll = if (ctx.main_output.count > visible_lines) ctx.main_output.count - visible_lines else 0;

    // Ensure scroll offset is valid
    if (ctx.main_output.scroll_offset > max_scroll) {
        ctx.main_output.scroll_offset = max_scroll;
    }

    for (0..visible_lines) |display_idx| {
        const output_idx = ctx.main_output.scroll_offset + display_idx;
        const screen_row = start_row + display_idx;

        if (output_idx < ctx.main_output.count and screen_row < 21) { // Don't overlap input area
            const line: []const u8 = std.mem.sliceTo(&ctx.main_output.lines[output_idx], 0);
            if (line.len > 0) {
                vga.putString(0, screen_row, line, 0x0F);
            }
        }
    }

    // Show scroll indicator if there are more lines
    if (ctx.main_output.count > visible_lines) {
        var scroll_info: [30]u8 = undefined;
        if (std.fmt.bufPrint(scroll_info[0..], "[{d}-{d}/{d}]", .{ ctx.main_output.scroll_offset + 1, @min(ctx.main_output.scroll_offset + visible_lines, ctx.main_output.count), ctx.main_output.count })) |result| {
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

pub fn renderLogsScreen(ctx: *UIContext) void {
    vga.putStringCentered(6, "Kernel Logs", @intFromEnum(Color.White));
    vga.putString(0, 7, "=" ** vga.VGA_WIDTH, @intFromEnum(Color.DarkGray));
    vga.putString(5, 8, "Use Up/Down arrows to scroll through logs", @intFromEnum(Color.LightGray));

    // Display scrollable logs
    const start_row = 10;
    const visible_lines = 13; // Lines 10-22 visible
    const max_scroll = if (ctx.logs.count > visible_lines) ctx.logs.count - visible_lines else 0;

    // Ensure scroll offset is valid
    if (ctx.logs.scroll_offset > max_scroll) {
        ctx.logs.scroll_offset = max_scroll;
    }

    for (0..visible_lines) |display_idx| {
        const log_idx = ctx.logs.scroll_offset + display_idx;
        const screen_row = start_row + display_idx;

        if (log_idx < ctx.logs.count and screen_row < vga.VGA_HEIGHT - 2) {
            const log_line: []const u8 = std.mem.sliceTo(&ctx.logs.lines[log_idx], 0);
            if (log_line.len > 0) {
                // Limit display to screen width
                const display_len = @min(log_line.len, vga.VGA_WIDTH);
                vga.putString(0, screen_row, log_line[0..display_len], @intFromEnum(Color.Yellow));
            }
        }
    }

    // Show scroll info
    var info_buffer: [50]u8 = undefined;
    if (ctx.logs.count > visible_lines) {
        if (std.fmt.bufPrint(info_buffer[0..], "Logs [{d}-{d}/{d}] - Total: {d}/50", .{ ctx.logs.scroll_offset + 1, @min(ctx.logs.scroll_offset + visible_lines, ctx.logs.count), ctx.logs.count, ctx.logs.count })) |result| {
            vga.putString(2, vga.VGA_HEIGHT - 1, result, @intFromEnum(Color.DarkGray));
        } else |_| {
            vga.putString(2, vga.VGA_HEIGHT - 1, "Scroll info error", @intFromEnum(Color.DarkGray));
        }
    } else {
        if (std.fmt.bufPrint(info_buffer[0..], "Total logs: {d}/50", .{ctx.logs.count})) |result| {
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

pub fn renderCurrentScreen(ctx: *UIContext) void {
    // Clear screen (keep header)
    var row: usize = 5;
    while (row < vga.VGA_HEIGHT) : (row += 1) {
        var col: usize = 0;
        while (col < vga.VGA_WIDTH) : (col += 1) {
            vga.putChar(col, row, ' ', @intFromEnum(Color.LightGray)); // Clear with default colors
        }
    }

    drawHeader(ctx); // Redraw with updated indicators

    switch (ctx.current_screen) {
        .Main => renderMainScreen(ctx),
        .Status => renderStatusScreen(),
        .Logs => renderLogsScreen(ctx),
        .About => renderAboutScreen(),
    }
}

pub fn addLog(ctx: *UIContext, message: []const u8) void {
    ctx.logs.addLine(message);
}

pub fn showWindowsMenu(ctx: *UIContext) void {
    ctx.menu_visible = true;
    ctx.menu_search.clear();
}

pub fn hideWindowsMenu(ctx: *UIContext) void {
    ctx.menu_visible = false;
}

pub fn drawWindowsMenu(ctx: *const UIContext) void {
    if (!ctx.menu_visible) return;

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
    if (ctx.menu_search.length > 0) {
        const display_len = @min(ctx.menu_search.length, search_width - 1);
        const search_text: []const u8 = ctx.menu_search.data[0..display_len];
        vga.putString(search_start, start_row + 2, search_text, Color.makeColor(Color.Black, Color.LightGray));
    }

    // Bottom line: \------/
    vga.putChar(start_col, start_row + 3, '\\', Color.makeColor(Color.White, Color.Black)); // Bottom-left corner
    for (1..menu_width - 1) |i| {
        vga.putChar(start_col + i, start_row + 3, '-', Color.makeColor(Color.White, Color.Black)); // Bottom border
    }
    vga.putChar(start_col + menu_width - 1, start_row + 3, '/', Color.makeColor(Color.White, Color.Black)); // Bottom-right corner

    // Position cursor in search box
    const cursor_pos = @min(search_start + ctx.menu_search.cursor, search_start + search_width - 1);
    vga.setCursorPosition(cursor_pos, start_row + 2);
}

pub fn setup_ui(ctx: *UIContext) void {
    vga.showCursor();
    vga.setCursorPosition(4 + input.getHostname().len, 23); // Position at input area initially

    renderCurrentScreen(ctx); // This will draw header and main screen
    input.drawInput(ctx);

    // Add initial logs
    addLog(ctx, "Kernel started with VeigarOS v1.0");
    addLog(ctx, "VGA display initialized");
    addLog(ctx, "Keyboard driver loaded");
    addLog(ctx, "Multi-screen system active");
    addLog(ctx, "Press F1-F4 to switch screens");
}
