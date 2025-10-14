const std = @import("std");

pub const ScreenType = enum { Main, Status, Logs, About };

// Reusable buffer with cursor/length
pub const TextBuffer = struct {
    data: []u8,
    length: usize = 0,
    cursor: usize = 0,

    pub fn clear(self: *TextBuffer) void {
        self.length = 0;
        self.cursor = 0;
        @memset(self.data, 0);
    }

    pub fn insertChar(self: *TextBuffer, char: u8, max_length: usize) void {
        if (self.length >= max_length) return;

        // Shift characters right to make room
        if (self.cursor < self.length) {
            var i = self.length;
            while (i > self.cursor) {
                self.data[i] = self.data[i - 1];
                i -= 1;
            }
        }
        self.data[self.cursor] = char;
        self.length += 1;
        self.cursor += 1;
    }

    pub fn deleteChar(self: *TextBuffer) void {
        if (self.cursor == 0 or self.length == 0) return;

        self.cursor -= 1;
        // Shift characters left
        for (self.cursor..self.length - 1) |i| {
            self.data[i] = self.data[i + 1];
        }
        self.length -= 1;
        self.data[self.length] = 0;
    }

    pub fn startsWith(self: *TextBuffer, prefix: []const u8) bool {
        if (self.length < prefix.len) return false;
        for (prefix, 0..prefix.len) |c, i| {
            if (self.data[i] != c) return false;
        }
        return true;
    }
};

// Scrollable output area
pub const ScrollableOutput = struct {
    lines: [][80]u8,
    count: usize = 0,
    scroll_offset: usize = 0,

    pub fn addLine(self: *ScrollableOutput, message: []const u8) void {
        if (self.count < self.lines.len) {
            // Clear the line first
            @memset(&self.lines[self.count], 0);
            // Copy message with length limit
            const copy_len = @min(message.len, 79);
            @memcpy(self.lines[self.count][0..copy_len], message[0..copy_len]);
            self.count += 1;
        } else {
            // Scroll lines up when buffer is full
            for (1..self.lines.len) |i| {
                self.lines[i - 1] = self.lines[i];
            }
            // Clear last line and add new message
            @memset(&self.lines[self.lines.len - 1], 0);
            const copy_len = @min(message.len, 79);
            @memcpy(self.lines[self.lines.len - 1][0..copy_len], message[0..copy_len]);
        }
        // Auto-scroll to show newest
        self.scroll_offset = 0;
    }

    pub fn scrollUp(self: *ScrollableOutput, visible_lines: usize) void {
        const max_scroll = if (self.count > visible_lines) self.count - visible_lines else 0;
        if (self.scroll_offset < max_scroll) {
            self.scroll_offset += 1;
        }
    }

    pub fn scrollDown(self: *ScrollableOutput) void {
        if (self.scroll_offset > 0) {
            self.scroll_offset -= 1;
        }
    }

    pub fn clear(self: *ScrollableOutput) void {
        self.count = 0;
        self.scroll_offset = 0;
        for (self.lines) |*line| {
            @memset(line, 0);
        }
    }
};

pub const UIContext = struct {
    current_screen: ScreenType,

    // Storage arrays
    main_output_storage: [25][80]u8,
    main_input_storage: [256]u8,
    log_storage: [50][80]u8,
    menu_storage: [64]u8,

    // Logical views
    main_output: ScrollableOutput,
    main_input: TextBuffer,
    logs: ScrollableOutput,
    menu_visible: bool,
    menu_search: TextBuffer,

    pub fn init() UIContext {
        return .{
            .current_screen = .Main,
            .main_output_storage = [_][80]u8{[_]u8{0} ** 80} ** 25,
            .main_input_storage = [_]u8{0} ** 256,
            .log_storage = [_][80]u8{[_]u8{0} ** 80} ** 50,
            .menu_storage = [_]u8{0} ** 64,
            .main_output = .{ .lines = undefined, .count = 0, .scroll_offset = 0 },
            .main_input = .{ .data = undefined, .length = 0, .cursor = 0 },
            .logs = .{ .lines = undefined, .count = 0, .scroll_offset = 0 },
            .menu_visible = false,
            .menu_search = .{ .data = undefined, .length = 0, .cursor = 0 },
        };
    }

    pub fn initViews(self: *UIContext) void {
        self.main_output.lines = &self.main_output_storage;
        self.main_input.data = &self.main_input_storage;
        self.logs.lines = &self.log_storage;
        self.menu_search.data = &self.menu_storage;
    }
};
