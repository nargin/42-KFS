const std = @import("std");
const vga = @import("../drivers/vga.zig");
const Color = vga.Color;
const input = @import("input.zig");
const UIContext = @import("context.zig").UIContext;

const CONTENT_ROW: usize = 1;
const CONTENT_END: usize = 22;
const VISIBLE_LINES: usize = CONTENT_END - CONTENT_ROW + 1; // 22

pub fn renderScreen(ctx: *UIContext) void {
    // Clear all content rows
    var row: usize = 0;
    while (row < vga.VGA_HEIGHT) : (row += 1) {
        vga.putString(0, row, " " ** vga.VGA_WIDTH, Color.make(Color.LightGray, Color.Black));
    }

    // Row 0: title bar
    vga.putString(0, 0, "\xCD" ** vga.VGA_WIDTH, Color.make(Color.Yellow, Color.Black));
    vga.putStringCentered(0, "[ KFS ]", Color.make(Color.White, Color.Black));

    const visible = VISIBLE_LINES;
    const count = ctx.main_output.count;

    const max_scroll = if (count > visible) count - visible else 0;
    if (ctx.main_output.scroll_offset > max_scroll)
        ctx.main_output.scroll_offset = max_scroll;

    const start = if (count > visible)
        count - visible - ctx.main_output.scroll_offset
    else
        0;

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

    // Scroll indicator on title bar when scrolled
    if (count > visible and ctx.main_output.scroll_offset > 0) {
        var buf: [16]u8 = undefined;
        if (std.fmt.bufPrint(&buf, "[{d}-{d}/{d}]", .{
            start + 1,
            @min(start + visible, count),
            count,
        })) |result| {
            vga.putString(vga.VGA_WIDTH - result.len, 0, result, Color.make(Color.DarkGray, Color.Black));
        } else |_| {}
    }
}

pub fn addLog(ctx: *UIContext, message: []const u8) void {
    ctx.main_output.addLine(message);
}

pub fn setup_ui(ctx: *UIContext) void {
    vga.showCursor();
    vga.setCursorPosition(4, 24); // Position cursor after prompt

    addLog(ctx, "KFS booted");
    addLog(ctx, "GDT loaded at 0x00000800 (7 entries)");
    addLog(ctx, "Type /help for commands");

    renderScreen(ctx);
    input.drawInput(ctx);
}
