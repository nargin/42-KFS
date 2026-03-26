pub const ScreenType = enum { Main, Status, Logs, About };

pub fn ScrollableOutput(comptime max_lines: usize) type {
    return struct {
        const Self = @This();

        lines: [max_lines][80]u8 = [_][80]u8{[_]u8{0} ** 80} ** max_lines,
        count: usize = 0,
        scroll_offset: usize = 0,

        pub fn addLine(self: *Self, message: []const u8) void {
            if (self.count < max_lines) {
                @memset(&self.lines[self.count], 0);
                const n = @min(message.len, 79);
                @memcpy(self.lines[self.count][0..n], message[0..n]);
                self.count += 1;
            } else {
                for (1..max_lines) |i| self.lines[i - 1] = self.lines[i];
                @memset(&self.lines[max_lines - 1], 0);
                const n = @min(message.len, 79);
                @memcpy(self.lines[max_lines - 1][0..n], message[0..n]);
            }
            // scroll_offset = 0 means "pinned to bottom" (newest content).
            // Adding a line keeps us pinned unless the user has scrolled up.
            if (self.scroll_offset > 0) self.scroll_offset += 1;
        }

        // scroll_offset is distance from the bottom:
        //   0           → show newest lines
        //   count - vis → show oldest lines
        // Clamping is done by the renderer, not here.
        pub fn scrollUp(self: *Self) void {
            self.scroll_offset += 1;
        }

        pub fn scrollDown(self: *Self) void {
            if (self.scroll_offset > 0) self.scroll_offset -= 1;
        }

        pub fn clear(self: *Self) void {
            self.count = 0;
            self.scroll_offset = 0;
            for (&self.lines) |*line| @memset(line, 0);
        }
    };
}

pub fn TextBuffer(comptime max_len: usize) type {
    return struct {
        const Self = @This();

        data: [max_len]u8 = [_]u8{0} ** max_len,
        length: usize = 0,
        cursor: usize = 0,

        pub fn clear(self: *Self) void {
            self.length = 0;
            self.cursor = 0;
            @memset(&self.data, 0);
        }

        pub fn insertChar(self: *Self, char: u8, max_length: usize) void {
            if (self.length >= max_length) return;
            if (self.cursor < self.length) {
                var i = self.length;
                while (i > self.cursor) : (i -= 1) self.data[i] = self.data[i - 1];
            }
            self.data[self.cursor] = char;
            self.length += 1;
            self.cursor += 1;
        }

        pub fn deleteChar(self: *Self) void {
            if (self.cursor == 0 or self.length == 0) return;
            self.cursor -= 1;
            for (self.cursor..self.length - 1) |i| self.data[i] = self.data[i + 1];
            self.length -= 1;
            self.data[self.length] = 0;
        }

        pub fn startsWith(self: *const Self, prefix: []const u8) bool {
            if (self.length < prefix.len) return false;
            for (prefix, 0..) |c, i| if (self.data[i] != c) return false;
            return true;
        }
    };
}

pub const UIContext = struct {
    current_screen: ScreenType = .Main,
    main_output: ScrollableOutput(25) = .{},
    main_input: TextBuffer(256) = .{},
    logs: ScrollableOutput(50) = .{},
    menu_visible: bool = false,
    menu_search: TextBuffer(64) = .{},

    // Debug logs -- Read only
    debug_logs: [50][80]u8,

    pub fn init() UIContext {
        return .{};
    }
};
