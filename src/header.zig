const std = @import("std");
const Console = @import("./console.zig").Console;
const ConsoleColors = @import("./console.zig").ConsoleColors;

pub fn drawHeader(console: *Console, title: []const u8) void {
    const orig_color = console.color;
    defer console.setColor(orig_color);

    console.setColors(.White, .LightMagenta);

    const rainbow: [6]ConsoleColors = .{
        .Red, .Yellow, .Green, .Cyan, .Blue, .Magenta,
    };

    for (0..rainbow.len) |i| {
        console.setColors(rainbow[i], rainbow[i]);
        console.putCharAt(' ', i, 0); // rainbow effect
    }

    console.setColors(.White, .LightMagenta); // header color

    for (rainbow.len..console.config.width) |x| {
        console.putCharAt(' ', x, 0);
    }

    const title_len = title.len; // center title
    const start_col =
        if (title_len < console.config.width)
            (console.config.width - title_len) / 2
        else
            0;

    // Draw the title
    var i: usize = 0;
    while (i < title_len and start_col + i < console.config.width) : (i += 1) {
        console.putCharAt(title[i], start_col + i, 0);
    }

    // Move cursor to after header
    console.row = 2;
    console.column = 0;
}
