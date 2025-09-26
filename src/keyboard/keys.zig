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

    _,

    pub fn getName(self: Key) []const u8 {
        return switch (self) {
            .Escape => "Escape",
            .Backspace => "Backspace",
            .Tab => "Tab",
            .Enter => "Enter",
            .LeftCtrl => "Left Ctrl",
            .LeftShift => "Left Shift",
            .RightShift => "Right Shift",
            .LeftAlt => "Left Alt",
            .Space => "Space",
            .CapsLock => "Caps Lock",

            .F1 => "F1",
            .F2 => "F2",
            .F3 => "F3",
            .F4 => "F4",
            .F5 => "F5",
            .F6 => "F6",
            .F7 => "F7",
            .F8 => "F8",
            .F9 => "F9",
            .F10 => "F10",
            .F11 => "F11",
            .F12 => "F12",

            .Key1 => "1",
            .Key2 => "2",
            .Key3 => "3",
            .Key4 => "4",
            .Key5 => "5",
            .Key6 => "6",
            .Key7 => "7",
            .Key8 => "8",
            .Key9 => "9",
            .Key0 => "0",
            .Minus => "-",
            .Equals => "=",

            .Q => "Q",
            .W => "W",
            .E => "E",
            .R => "R",
            .T => "T",
            .Y => "Y",
            .U => "U",
            .I => "I",
            .O => "O",
            .P => "P",
            .LeftBracket => "[",
            .RightBracket => "]",

            .A => "A",
            .S => "S",
            .D => "D",
            .F => "F",
            .G => "G",
            .H => "H",
            .J => "J",
            .K => "K",
            .L => "L",
            .Semicolon => ";",
            .Quote => "'",
            .Backtick => "`",

            .Backslash => "\\",
            .Z => "Z",
            .X => "X",
            .C => "C",
            .V => "V",
            .B => "B",
            .N => "N",
            .M => "M",
            .Comma => ",",
            .Period => ".",
            .Slash => "/",

            .ArrowUp => "Arrow Up",
            .ArrowDown => "Arrow Down",
            .ArrowLeft => "Arrow Left",
            .ArrowRight => "Arrow Right",
            .LeftWindows => "Left Windows",
            .RightWindows => "Right Windows",
            .Menu => "Menu",
            .Insert => "Insert",
            .Delete => "Delete",
            .Home => "Home",
            .End => "End",
            .PageUp => "Page Up",
            .PageDown => "Page Down",

            _ => "Unknown",
        };
    }
};
