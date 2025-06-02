const Console = @import("console.zig").Console;

pub const Logger = struct {
    console: *Console,

    pub fn init(console: *Console) Logger {
        return Logger{ .console = console };
    }

    pub fn info(self: *Logger, comptime fmt: []const u8, args: anytype) void {
        const org_color = self.console.color;
        self.console.setColors(.Blue, .Black);
        self.console.printf("[INFO] " ++ fmt ++ "\n", args);
        self.console.setColor(org_color);
    }

    pub fn warn(self: *Logger, comptime fmt: []const u8, args: anytype) void {
        const org_color = self.console.color;
        self.console.setColors(.Yellow, .Black);
        self.console.printf("[WARN] " ++ fmt ++ "\n", args);
        self.console.setColor(org_color);
    }

    pub fn err(self: *Logger, comptime fmt: []const u8, args: anytype) void {
        const org_color = self.console.color;
        self.console.setColors(.Red, .Black);
        self.console.printf("[ERROR] " ++ fmt ++ "\n", args);
        self.console.setColor(org_color);
    }
};
