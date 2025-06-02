const fmt = @import("std").fmt;
const Writer = @import("std").io.Writer;

pub const ConsoleConfig = struct {
    width: usize = 80,
    height: usize = 25,
    memory_address: usize = 0xB8000,
    default_fg: ConsoleColors = .LightGray,
    default_bg: ConsoleColors = .Black,
};

pub const ConsoleColors = enum(u8) {
    Black = 0,
    Blue = 1,
    Green = 2,
    Cyan = 3,
    Red = 4,
    Magenta = 5,
    Brown = 6,
    LightGray = 7,
    DarkGray = 8,
    LightBlue = 9,
    LightGreen = 10,
    LightCyan = 11,
    LightRed = 12,
    LightMagenta = 13,
    Yellow = 14,
    White = 15,
};

pub const Console = struct {
    color: u8,
    row: usize = 0,
    column: usize = 0,
    config: ConsoleConfig,
    buffer: [*]volatile u16,

    pub fn init(config: ConsoleConfig) Console {
        var console = Console{
            .config = config,
            .color = vgaEntryColor(config.default_fg, config.default_bg),
            .buffer = @as([*]volatile u16, @ptrFromInt(config.memory_address)),
        };
        console.clear();
        return console;
    }

    fn vgaEntryColor(fg: ConsoleColors, bg: ConsoleColors) u8 {
        return @intFromEnum(fg) | (@intFromEnum(bg) << 4);
    }

    fn vgaEntry(uc: u8, new_color: u8) u16 {
        return @as(u16, uc) | (@as(u16, new_color) << 8);
    }

    pub fn setColor(self: *Console, color: u8) void {
        self.color = color;
    }

    pub fn setColors(self: *Console, fg: ConsoleColors, bg: ConsoleColors) void {
        self.color = vgaEntryColor(fg, bg);
    }

    pub fn clear(self: *Console) void {
        const entry = vgaEntry(' ', self.color);
        for (0..self.config.width * self.config.height) |i| {
            self.buffer[i] = entry;
        }
        self.column = 0;
        self.row = 0;
    }

    pub fn putCharAt(self: *Console, c: u8, x: usize, y: usize) void {
        if (x >= self.config.width or y >= self.config.height) return;
        const index = y * self.config.width + x;
        self.buffer[index] = vgaEntry(c, self.color);
    }

    pub fn putChar(self: *Console, c: u8) void {
        switch (c) {
            '\n' => {
                self.column = 0;
                self.row += 1;
            },
            '\r' => {
                self.column = 0;
            },
            // '\t' => {
            //     self.column = (self.column + 4) & !3;
            // },
            else => {
                self.putCharAt(c, self.column, self.row);
                self.column += 1;
            },
        }

        if (self.column >= self.config.width) {
            self.column = 0;
            self.row += 1;
        }

        if (self.row >= self.config.height) {
            self.scrollUp();
            self.row = self.config.height - 1;
        }
    }

    pub fn scrollUp(self: *Console) void {
        // Move all lines up by one
        const line_size = self.config.width;
        const screen_size = self.config.width * self.config.height;

        for (line_size..screen_size) |i| {
            self.buffer[i - line_size] = self.buffer[i];
        }

        // Clear the last line
        const last_line_start = (self.config.height - 1) * self.config.width;
        const entry = vgaEntry(' ', self.color);
        for (last_line_start..screen_size) |i| {
            self.buffer[i] = entry;
        }
    }

    pub fn puts(self: *Console, data: []const u8) void {
        for (data) |c| {
            self.putChar(c);
        }
    }

    pub fn printf(self: *Console, comptime format: []const u8, args: anytype) void {
        const writer = Writer(*Console, error{}, writeCallback){
            .context = self,
        };
        fmt.format(writer, format, args) catch unreachable;
    }

    fn writeCallback(console: *Console, string: []const u8) error{}!usize {
        console.puts(string);
        return string.len;
    }
};
