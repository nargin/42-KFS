const std = @import("std");
const vga = @import("../drivers/vga.zig");
const Color = vga.Color;
const input = @import("input.zig");
const UIContext = @import("context.zig").UIContext;
pub const ScreenType = @import("context.zig").ScreenType;

// Layout
//   Row 0    : header title     (magenta)
//   Row 1    : header nav       (magenta)
//   Row 2    : separator ══════
//   Rows 3-19: content area     (17 lines)
//   Row 20   : separator (drawn by drawInput)
//   Row 21   : input line
const CONTENT_ROW: usize = 3;
const CONTENT_END: usize = 19;
const VISIBLE_LINES: usize = CONTENT_END - CONTENT_ROW + 1; // 17

pub fn switchToScreen(ctx: *UIContext, screen: ScreenType) void {
    ctx.current_screen = screen;
    input.switchToScreen(ctx, screen);
    renderCurrentScreen(ctx);
    input.drawInput(ctx);
}

fn indicatorColor(ctx: *const UIContext, indicator: ScreenType) u8 {
    return if (ctx.current_screen == indicator)
        Color.make(Color.Black, Color.Yellow)
    else
        Color.make(Color.White, Color.Magenta);
}

pub fn drawHeader(ctx: *const UIContext) void {
    const hdr = Color.make(Color.White, Color.Magenta);
    const sep = Color.make(Color.Yellow, Color.Black);

    // Clear rows 0-1 with magenta background
    vga.putString(0, 0, " " ** vga.VGA_WIDTH, hdr);
    vga.putString(0, 1, " " ** vga.VGA_WIDTH, hdr);

    // Row 0: title
    vga.putStringCentered(0, "[ VeigarOS ]", Color.make(Color.Yellow, Color.Magenta));

    // Row 1: nav tabs
    vga.putString(1, 1, "F1:Main", indicatorColor(ctx, .Main));
    vga.putString(11, 1, "F2:Status", indicatorColor(ctx, .Status));
    vga.putString(23, 1, "F3:Logs", indicatorColor(ctx, .Logs));
    vga.putString(33, 1, "F4:About", indicatorColor(ctx, .About));

    // Row 2: separator
    vga.putString(0, 2, "\xCD" ** vga.VGA_WIDTH, sep);
}

pub fn renderMainScreen(ctx: *UIContext) void {
    const visible = VISIBLE_LINES;
    const count = ctx.main_output.count;

    // Clamp: can't scroll past the oldest line
    const max_scroll = if (count > visible) count - visible else 0;
    if (ctx.main_output.scroll_offset > max_scroll)
        ctx.main_output.scroll_offset = max_scroll;

    // scroll_offset = 0 → start at newest; increasing → older content
    const start = if (count > visible)
        count - visible - ctx.main_output.scroll_offset
    else
        0;

    // Bottom-anchor: when fewer lines than visible, push output to bottom rows
    const row_offset = if (count < visible) visible - count else 0;

    for (0..visible) |i| {
        const out_idx = start + i;
        const screen_row = CONTENT_ROW + row_offset + i;
        if (screen_row > CONTENT_END) break;
        if (out_idx < count) {
            const line = std.mem.sliceTo(&ctx.main_output.lines[out_idx], 0);
            if (line.len > 0)
                vga.putString(0, screen_row, line, Color.make(Color.LightGray, Color.Black));
        }
    }

    // Scroll indicator on separator row
    if (count > visible) {
        var buf: [16]u8 = undefined;
        if (std.fmt.bufPrint(&buf, "[{d}-{d}/{d}]", .{
            start + 1,
            @min(start + visible, count),
            count,
        })) |result| {
            vga.putString(72 - result.len, 2, result, Color.make(Color.DarkGray, Color.Black));
        } else |_| {}
    }
}

pub fn renderStatusScreen() void {
    const title = Color.make(Color.Yellow, Color.Black);
    const ok = Color.make(Color.LightGreen, Color.Black);
    const warn = Color.make(Color.LightRed, Color.Black);
    const info = Color.make(Color.White, Color.Black);

    vga.putStringCentered(4, "[ System Status ]", title);
    vga.putString(0, 5, "\xCD" ** vga.VGA_WIDTH, Color.make(Color.DarkGray, Color.Black));

    vga.putString(4, 7, "Kernel  : VeigarOS v1.0", ok);
    vga.putString(4, 8, "Arch    : x86 32-bit protected mode", info);
    vga.putString(4, 9, "GDT     : loaded  (7 entries @ 0x800)", ok);
    vga.putString(4, 10, "IDT     : not loaded", warn);
    vga.putString(4, 11, "Paging  : not enabled", warn);
    vga.putString(4, 13, "VGA     : text mode 80x25", info);
    vga.putString(4, 14, "Stack   : 16 KB @ .bss", info);
}

pub fn renderLogsScreen(ctx: *UIContext) void {
    const title = Color.make(Color.Yellow, Color.Black);
    const sep = Color.make(Color.DarkGray, Color.Black);
    const log_c = Color.make(Color.Yellow, Color.Black);

    vga.putStringCentered(CONTENT_ROW, "[ Kernel Logs ]", title);
    vga.putString(0, CONTENT_ROW + 1, "\xCD" ** vga.VGA_WIDTH, sep);

    const start_row: usize = CONTENT_ROW + 2;
    const visible: usize = CONTENT_END - start_row + 1; // 15
    const count = ctx.logs.count;

    const max_scroll = if (count > visible) count - visible else 0;
    if (ctx.logs.scroll_offset > max_scroll)
        ctx.logs.scroll_offset = max_scroll;

    const start = if (count > visible)
        count - visible - ctx.logs.scroll_offset
    else
        0;

    for (0..visible) |i| {
        const log_idx = start + i;
        const screen_row = start_row + i;
        if (log_idx < count) {
            const line = std.mem.sliceTo(&ctx.logs.lines[log_idx], 0);
            if (line.len > 0) {
                const len = @min(line.len, vga.VGA_WIDTH);
                vga.putString(0, screen_row, line[0..len], log_c);
            }
        }
    }

    // Log count on separator
    if (count > 0) {
        var buf: [24]u8 = undefined;
        if (std.fmt.bufPrint(&buf, "logs: {d}/{d}", .{ count, ctx.logs.lines.len })) |r| {
            vga.putString(vga.VGA_WIDTH - r.len, CONTENT_ROW + 1, r, sep);
        } else |_| {}
    }
}

pub fn renderAboutScreen() void {
    vga.putStringCentered(8, "VeigarOS", Color.make(Color.Yellow, Color.Black));
    vga.putStringCentered(10, "A bare metal x86 kernel in Zig", Color.make(Color.White, Color.Black));
    vga.putStringCentered(12, "F1-F4 to navigate  |  Tab to cycle", Color.make(Color.DarkGray, Color.Black));
}

pub fn renderCurrentScreen(ctx: *UIContext) void {
    // Clear content area rows 3-24 (header rows 0-2 are redrawn by drawHeader)
    var row: usize = CONTENT_ROW;
    while (row < vga.VGA_HEIGHT) : (row += 1) {
        var col: usize = 0;
        while (col < vga.VGA_WIDTH) : (col += 1) {
            vga.putChar(col, row, ' ', Color.make(Color.LightGray, Color.Black));
        }
    }

    drawHeader(ctx);

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

    const menu_width = 50;
    const menu_height = 4;
    const start_col = (vga.VGA_WIDTH - menu_width) / 2;
    const start_row = (vga.VGA_HEIGHT - menu_height) / 2;

    const border = Color.make(Color.White, Color.Black);
    const field = Color.make(Color.Black, Color.LightGray);
    const label = Color.make(Color.White, Color.Black);

    // Top border
    vga.putChar(start_col, start_row, '/', border);
    for (1..menu_width - 1) |i| vga.putChar(start_col + i, start_row, '-', border);
    vga.putChar(start_col + menu_width - 1, start_row, '\\', border);

    // Search label row
    vga.putChar(start_col, start_row + 1, '|', border);
    for (1..menu_width - 1) |i| vga.putChar(start_col + i, start_row + 1, ' ', label);
    vga.putString(start_col + 2, start_row + 1, "Search:", label);
    vga.putChar(start_col + menu_width - 1, start_row + 1, '|', border);

    // Input field row
    const search_start = start_col + 2;
    const search_width = menu_width - 4;
    vga.putChar(start_col, start_row + 2, '|', border);
    for (0..search_width) |i| vga.putChar(search_start + i, start_row + 2, ' ', field);
    vga.putChar(start_col + menu_width - 1, start_row + 2, '|', border);
    if (ctx.menu_search.length > 0) {
        const len = @min(ctx.menu_search.length, search_width - 1);
        vga.putString(search_start, start_row + 2, ctx.menu_search.data[0..len], field);
    }

    // Bottom border
    vga.putChar(start_col, start_row + 3, '\\', border);
    for (1..menu_width - 1) |i| vga.putChar(start_col + i, start_row + 3, '-', border);
    vga.putChar(start_col + menu_width - 1, start_row + 3, '/', border);

    vga.setCursorPosition(
        @min(search_start + ctx.menu_search.cursor, search_start + search_width - 1),
        start_row + 2,
    );
}

pub fn setup_ui(ctx: *UIContext) void {
    vga.showCursor();
    vga.setCursorPosition(4 + input.getHostname().len, 21);

    renderCurrentScreen(ctx);
    input.drawInput(ctx);

    addLog(ctx, "VeigarOS started");
    addLog(ctx, "GDT loaded at 0x00000800 (7 entries)");
    addLog(ctx, "VGA text mode 80x25 active");
    addLog(ctx, "Keyboard driver ready");
    addLog(ctx, "Type /help for commands");
}

pub fn renderDebugScreen(ctx: *UIContext) void {
    vga.clearScreen(@intFromEnum(Color.Black));

    for (0..80) |index| {
        vga.putString(index, 0, &(ctx.debug_logs[index]), @intFromEnum(Color.White));
    }

    renderCurrentScreen(ctx);
}
