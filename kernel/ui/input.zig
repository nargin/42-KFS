const std = @import("std");
const vga = @import("../drivers/vga.zig");
const screens = @import("./screens.zig");
const UIContext = @import("context.zig").UIContext;
const ScreenType = @import("context.zig").ScreenType;
const SpecialKey = @import("../drivers/keyboard.zig").SpecialKey;
const Key = @import("../drivers/keyboard.zig").Key;
const ASCII = @import("../drivers/keyboard.zig").ASCII;

var HOSTNAME_BUF: [32]u8 = undefined;
var HOSTNAME_LEN: usize = 4;

pub fn getHostname() []const u8 {
    return HOSTNAME_BUF[0..HOSTNAME_LEN];
}

pub fn initHostname() void {
    const default_name = "user";
    @memcpy(HOSTNAME_BUF[0..default_name.len], default_name);
    HOSTNAME_LEN = default_name.len;
}

pub fn setHostname(name: []const u8) void {
    const copy_len = @min(name.len, 32);
    @memcpy(HOSTNAME_BUF[0..copy_len], name[0..copy_len]);
    HOSTNAME_LEN = copy_len;
}

pub fn getPrompt(buffer: []u8) []const u8 {
    const prefix = "> ";
    const suffix = ": ";
    const hostname = getHostname();

    var pos: usize = 0;
    @memcpy(buffer[pos .. pos + prefix.len], prefix);
    pos += prefix.len;
    @memcpy(buffer[pos .. pos + hostname.len], hostname);
    pos += hostname.len;
    @memcpy(buffer[pos .. pos + suffix.len], suffix);
    pos += suffix.len;

    return buffer[0..pos];
}

// Display constants
const INPUT_ROW = 24;
const SEPARATOR_ROW = 23;
const MAX_INPUT_BUFFER_SIZE = 255;
const MAX_MENU_SEARCH_SIZE = 63;
const MENU_SEARCH_DISPLAY_WIDTH = 60;

pub fn strcmp(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    for (a, 0..a.len) |c, i| {
        if (c != b[i]) return false;
    }
    return true;
}

pub fn handleCommand(ctx: *UIContext) void {
    const command = ctx.main_input.data[1..ctx.main_input.length]; // Skip the leading '/'

    if (strcmp(command, "clear")) {
        ctx.main_output.clear();
    } else if (strcmp(command, "memmap")) {
        printMemoryMap(ctx);
    } else if (strcmp(command, "help")) {
        ctx.main_output.addLine("Commands: /clear, /help, /memmap, /sethostname <name>");
    } else if (ctx.main_input.startsWith("/sethostname")) {
        var hostname_msg: [80]u8 = [_]u8{0} ** 80;
        // Skip "/sethostname " (13 chars)
        var start: usize = 12;
        while (start < ctx.main_input.length and ctx.main_input.data[start] == ' ') {
            start += 1;
        }
        if (start >= ctx.main_input.length) {
            ctx.main_output.addLine("Usage: /sethostname <name>");
            return;
        }
        const new_name = ctx.main_input.data[start..ctx.main_input.length];
        if (new_name.len == 0 or new_name.len > 32) {
            ctx.main_output.addLine("Hostname must be 1-32 characters");
            return;
        }
        setHostname(new_name);
        const prefix = "Hostname changed to: ";
        @memcpy(hostname_msg[0..prefix.len], prefix);
        @memcpy(hostname_msg[prefix.len .. prefix.len + new_name.len], new_name);
        ctx.main_output.addLine(hostname_msg[0 .. prefix.len + new_name.len]);
    } else {
        ctx.main_output.addLine("Unknown command. Type /help for a list of commands.");
    }
}

pub fn drawInput(ctx: *UIContext) void {
    // Only draw input for Main screen
    if (ctx.current_screen != .Main) return;

    // Draw input separator line
    vga.putString(0, SEPARATOR_ROW, "\xCD" ** vga.VGA_WIDTH, 0x1E);

    // Build and draw prompt
    var prompt_buf: [64]u8 = undefined;
    const prompt = getPrompt(&prompt_buf);
    vga.putString(0, INPUT_ROW, prompt, 0x0B); // Cyan on black

    // Clear input line after prompt
    var col: usize = prompt.len;
    while (col < vga.VGA_WIDTH) : (col += 1) {
        vga.putChar(col, INPUT_ROW, ' ', 0x07); // Clear with default colors
    }

    // Display current input text (limit to available screen width)
    if (ctx.main_input.length > 0) {
        const available_width = vga.VGA_WIDTH - prompt.len;
        const display_len = @min(ctx.main_input.length, available_width);
        const display_text = ctx.main_input.data[0..display_len];
        vga.putString(prompt.len, INPUT_ROW, display_text, 0x0F); // White on black
    }

    // Position hardware cursor at input position
    const cursor_pos = @min(prompt.len + ctx.main_input.cursor, vga.VGA_WIDTH - 1);
    vga.setCursorPosition(cursor_pos, INPUT_ROW);
}

pub fn processInput(ctx: *UIContext) void {
    if (ctx.main_input.length == 0) return;

    if (ctx.main_input.startsWith("/")) {
        // Echo the command to main output
        var echo: [80]u8 = [_]u8{0} ** 80;
        const prefix = "> ";
        @memcpy(echo[0..prefix.len], prefix);
        const copy_len = @min(ctx.main_input.length, 80 - prefix.len);
        @memcpy(echo[prefix.len .. prefix.len + copy_len], ctx.main_input.data[0..copy_len]);
        ctx.main_output.addLine(echo[0 .. prefix.len + copy_len]);

        handleCommand(ctx);
        ctx.main_input.clear();
        screens.renderCurrentScreen(ctx);
    } else {
        // Create a log message with the user input
        var log_buffer: [80]u8 = [_]u8{0} ** 80;
        const hostname = getHostname();
        const suffix = ": ";
        var pos: usize = 0;
        @memcpy(log_buffer[pos .. pos + hostname.len], hostname);
        pos += hostname.len;
        @memcpy(log_buffer[pos .. pos + suffix.len], suffix);
        pos += suffix.len;
        const copy_len = @min(ctx.main_input.length, 80 - pos - 1);

        @memcpy(log_buffer[pos .. pos + copy_len], ctx.main_input.data[0..copy_len]);
        screens.addLog(ctx, log_buffer[0 .. pos + copy_len]);
    }

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
        } else {
            ctx.main_input.clear();
            drawInput(ctx);
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
            // Calculate prompt length: "> " + hostname + ": "
            const prompt_len = 4 + getHostname().len;
            const available_input_chars = vga.VGA_WIDTH - prompt_len;
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
                    ctx.main_output.scrollUp();
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
                    ctx.logs.scrollUp();
                },
                .ArrowDown => {
                    ctx.logs.scrollDown();
                },
                else => {},
            }
        },
        .Status, .About, .Debug => {
            // No scrolling on status/about screens
        },
    }
}

pub fn switchToScreen(ctx: *UIContext, screen: ScreenType) void {
    _ = screen;
    // Handle cursor visibility based on current screen
    if (ctx.current_screen == .Main) {
        vga.showCursor();
        // Calculate prompt length: "> " + hostname + ": "
        const prompt_len = 4 + getHostname().len;
        vga.setCursorPosition(prompt_len + ctx.main_input.cursor, INPUT_ROW);
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
        @intFromEnum(Key.F12) => {
            screens.switchToScreen(ctx, .Debug);
            return;
        },
        @intFromEnum(Key.Tab) => {
            // Cycle through screens
            const next_screen: ScreenType = switch (ctx.current_screen) {
                .Main => .Status,
                .Status => .Logs,
                .Logs => .About,
                .About => .Main,
                .Debug => .Main,
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

fn printMemoryMap(ctx: *UIContext) void {
    const start: u32 = 0x00200000; // kernel load address
    const rows = 20;

    var row: u32 = 0;
    while (row < rows) : (row += 1) {
        const addr = start + row * 16;
        const bytes: [*]const u8 = @ptrFromInt(addr);
        var line: [80]u8 = [_]u8{' '} ** 80;
        var pos: usize = 0;

        // Address
        const hdr = std.fmt.bufPrint(line[pos..], "0x{X:0>8}  ", .{addr}) catch continue;
        pos += hdr.len;

        // Hex bytes
        for (0..16) |i| {
            const h = std.fmt.bufPrint(line[pos..], "{X:0>2}", .{bytes[i]}) catch continue;
            pos += h.len;
            if (i < 15) {
                line[pos] = ' ';
                pos += 1;
            }
        }

        // ASCII
        line[pos] = ' ';
        pos += 1;
        line[pos] = '|';
        pos += 1;
        for (0..16) |i| {
            const b = bytes[i];
            line[pos] = if (b >= 32 and b < 127) b else '.';
            pos += 1;
        }
        line[pos] = '|';
        pos += 1;

        ctx.main_output.addLine(line[0..pos]);
    }
}
