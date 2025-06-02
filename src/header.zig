const std = @import("std");
const Console = @import("./console.zig").Console;
const ConsoleColors = @import("./console.zig").ConsoleColors;

pub fn drawHeader(console: *Console, title: []const u8) void {
    const orig_color = console.color;

    // Set header colors (e.g., white on blue)
    const header_color = console.setColors(.White, .LightMagenta);

    // Rainbow colors for the start (adjust as you like)
    const rainbow: [6]ConsoleColors = .{
        .Red, .Yellow, .Green, .Cyan, .Blue, .Magenta,
    };

    // Fill the first row with spaces (background color)
    for (0..console.config.width) |x| {
        if (x < rainbow.len) {
            console.setColors(.White, rainbow[x % rainbow.len]);
        }
        console.putCharAt(' ', x, 0);
        header_color;
    }

    // Center the title
    const title_len = title.len;
    const start_col =
        if (title_len < console.config.width)
            (console.config.width - title_len) / 2
        else
            0;

    var i: usize = 0;
    while (i < title_len and start_col + i < console.config.width) : (i += 1) {
        console.putCharAt(title[i], start_col + i, 0);
    }

    console.row += 2;
    console.column = 0;

    // Restore original color
    console.setColor(orig_color);
}
