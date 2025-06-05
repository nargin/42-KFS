const fmt = @import("std").fmt;
const Writer = @import("std").io.Writer;

pub const ConsoleConfig = struct {
    width: usize = 80,
    height: usize = 25,
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

pub const ConsoleCell = struct {
    character: u8,
    color: u8,
};

pub const Console = struct {
    color: u8,
    row: usize = 0,
    column: usize = 0,
    config: ConsoleConfig,
    buffer: [25][80]ConsoleCell,

    pub fn init(config: ConsoleConfig) Console {
        var console = Console{
            .config = config,
            .color = vgaEntryColor(config.default_fg, config.default_bg),
            .buffer = undefined,
        };
        console.clear();
        return console;
    }

    fn vgaEntryColor(fg: ConsoleColors, bg: ConsoleColors) u8 {
        return @intFromEnum(fg) | (@intFromEnum(bg) << 4);
    }

    pub fn setColor(self: *Console, color: u8) void {
        self.color = color;
    }

    pub fn setColors(self: *Console, fg: ConsoleColors, bg: ConsoleColors) void {
        self.color = vgaEntryColor(fg, bg);
    }

    pub fn setColorAt(self: *Console, fg: ConsoleColors, bg: ConsoleColors, x: usize, y: usize) void {
        const c = vgaEntryColor(fg, bg);
        if (x >= self.config.width or y >= self.config.height) return;
        self.buffer[y][x] = ConsoleCell{
            .character = self.buffer[y][x].character,
            .color = c,
        };
    }

    pub fn clear(self: *Console) void {
        for (0..self.config.height) |y| {
            for (0..self.config.width) |x| {
                self.buffer[y][x] = ConsoleCell{
                    .character = ' ',
                    .color = self.color,
                };
            }
        }
        self.column = 0;
        self.row = 0;
    }

    pub fn putCharAt(self: *Console, c: u8, x: usize, y: usize) void {
        if (x >= self.config.width or y >= self.config.height) return;
        self.buffer[y][x] = ConsoleCell{
            .character = c,
            .color = self.color,
        };
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
            '\t' => {
                self.column = (self.column + 4);
            },
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
        for (1..self.config.height) |y| {
            for (0..self.config.width) |x| {
                self.buffer[y - 1][x] = self.buffer[y][x];
            }
        }

        // Clear the last line
        const last_row = self.config.height - 1;
        for (0..self.config.width) |x| {
            self.buffer[last_row][x] = ConsoleCell{
                .character = ' ',
                .color = self.color,
            };
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

    pub fn getCharAt(self: *Console, x: usize, y: usize) ?ConsoleCell {
        if (x >= self.config.width or y >= self.config.height) return null;
        return self.buffer[y][x];
    }

    pub fn getLine(self: *Console, y: usize, line_buffer: []u8) ?[]u8 {
        if (y >= self.config.height or line_buffer.len < self.config.width) return null;

        for (0..self.config.width) |x| {
            line_buffer[x] = self.buffer[y][x].character;
        }
        return line_buffer[0..self.config.width];
    }

    pub fn toVgaBuffer(self: *Console, vga_buffer: [*]volatile u16) void {
        for (0..self.config.height) |y| {
            for (0..self.config.width) |x| {
                const index = y * self.config.width + x;
                const cell = self.buffer[y][x];
                vga_buffer[index] = @as(u16, cell.character) | (@as(u16, cell.color) << 8);
            }
        }
    }
};
