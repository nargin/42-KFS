const std = @import("std");

pub const Key = enum(u8) {
    // Special keys
    Escape = 0x01,
    Backspace = 0x0E,
    Tab = 0x0F,
    Enter = 0x1C,
    LeftCtrl = 0x1D,
    LeftShift = 0x2A,
    RightShift = 0x36,
    LeftAlt = 0x38,
    Space = 0x39,
    CapsLock = 0x3A,

    // Function keys
    F1 = 0x3B,
    F2 = 0x3C,
    F3 = 0x3D,
    F4 = 0x3E,
    F5 = 0x3F,
    F6 = 0x40,
    F7 = 0x41,
    F8 = 0x42,
    F9 = 0x43,
    F10 = 0x44,
    F11 = 0x57,
    F12 = 0x58,

    // Number row
    Key1 = 0x02,
    Key2 = 0x03,
    Key3 = 0x04,
    Key4 = 0x05,
    Key5 = 0x06,
    Key6 = 0x07,
    Key7 = 0x08,
    Key8 = 0x09,
    Key9 = 0x0A,
    Key0 = 0x0B,
    Minus = 0x0C,
    Equals = 0x0D,

    // Top letter row
    Q = 0x10,
    W = 0x11,
    E = 0x12,
    R = 0x13,
    T = 0x14,
    Y = 0x15,
    U = 0x16,
    I = 0x17,
    O = 0x18,
    P = 0x19,
    LeftBracket = 0x1A,
    RightBracket = 0x1B,

    // Middle letter row
    A = 0x1E,
    S = 0x1F,
    D = 0x20,
    F = 0x21,
    G = 0x22,
    H = 0x23,
    J = 0x24,
    K = 0x25,
    L = 0x26,
    Semicolon = 0x27, // ;
    Quote = 0x28, // '
    Backtick = 0x29, // `

    // Bottom letter row
    Backslash = 0x2B,
    Z = 0x2C,
    X = 0x2D,
    C = 0x2E,
    V = 0x2F,
    B = 0x30,
    N = 0x31,
    M = 0x32,
    Comma = 0x33, // ,
    Period = 0x34, // .
    Slash = 0x35, // /

    ArrowUp = 0x48, // Extended
    ArrowDown = 0x50, // Extended
    ArrowLeft = 0x4B, // Extended
    ArrowRight = 0x4D, // Extended

    LeftWindows = 0x5B, // Extended
    RightWindows = 0x5C, // Extended
};

// Special keys that do not have a direct ASCII representation
pub const SpecialKey = enum {
    ArrowUp,
    ArrowDown,
    ArrowLeft,
    ArrowRight,
    WindowsKey,
};

// VGA uses 4-bit color values for foreground and background
// Format: background << 4 | foreground

pub const Color = enum(u8) {
    Black,
    Blue,
    Green,
    Cyan,
    Red,
    Magenta,
    Brown,
    LightGray,
    DarkGray,
    LightBlue,
    LightGreen,
    LightCyan,
    LightRed,
    LightMagenta,
    Yellow,
    White,

    pub fn makeColor(foreground: Color, background: Color) u8 {
        const fg = @intFromEnum(foreground);
        const bg = @intFromEnum(background);
        return fg | (bg << 4);
    }

    // Helper functions
    pub fn makeForegroundColor(color: Color) u8 {
        return @intFromEnum(color);
    }

    pub fn makeBackgroundColor(color: Color) u8 {
        return @intFromEnum(color) << 4;
    }
};

// ASCII Character Constants
// These are the actual character values sent to handleChar(),
// NOT the keyboard scancodes from the Key enum

pub const ASCII = struct {
    // Control characters
    pub const NULL = 0x00;
    pub const BACKSPACE = 0x08;
    pub const TAB = 0x09;
    pub const NEWLINE = 0x0A;
    pub const CARRIAGE_RETURN = 0x0D;
    pub const ESCAPE = 0x1B;
    pub const SPACE = 0x20;
    pub const DELETE = 0x7F;

    // Printable ASCII range
    pub const FIRST_PRINTABLE = 0x20; // Space
    pub const LAST_PRINTABLE = 0x7E; // ~

    // Common characters
    pub const ENTER = '\n';

    // Helper functions
    pub fn isPrintable(char: u8) bool {
        return char >= FIRST_PRINTABLE and char <= LAST_PRINTABLE;
    }

    pub fn isControl(char: u8) bool {
        return char < FIRST_PRINTABLE or char == DELETE;
    }

    pub fn getName(char: u8) []const u8 {
        return switch (char) {
            NULL => "NULL",
            BACKSPACE => "BACKSPACE",
            TAB => "TAB",
            NEWLINE => "NEWLINE",
            CARRIAGE_RETURN => "CARRIAGE_RETURN",
            ESCAPE => "ESCAPE",
            SPACE => "SPACE",
            DELETE => "DELETE",
            else => if (isPrintable(char)) "PRINTABLE" else "CONTROL",
        };
    }
};
