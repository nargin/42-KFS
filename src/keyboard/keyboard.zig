const std = @import("std");
const keys = @import("./keys.zig");
const Key = keys.Key;

const KEYBOARD_DATA_PORT: u16 = 0x60;
const KEYBOARD_STATUS_PORT: u16 = 0x64;

pub const KeyEvent = struct {
    scancode: u8,
    character: ?u8,
    pressed: bool,
    special: ?SpecialKey = null,
};

pub const SpecialKey = enum {
    ArrowUp,
    ArrowDown,
    ArrowLeft,
    ArrowRight,
    WindowsKey,
};

const scancode_to_char = [_]u8{
    0, 0, '1', '2', '3', '4', '5', '6', // 0x00-0x07
    '7', '8', '9', '0', '-', '=', 0x08, '\t', // 0x08-0x0F (0x0E = backspace, 0x0F = tab)
    'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', // 0x10-0x17
    'o', 'p', '[', ']', '\n', 0, 'a', 's', // 0x18-0x1F (0x1C = enter, 0x1D = ctrl)
    'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', // 0x20-0x27
    '\'', '`', 0, '\\', 'z', 'x', 'c', 'v', // 0x28-0x2F (0x2A = shift)
    'b', 'n', 'm', ',', '.', '/', 0, '*', // 0x30-0x37 (0x36 = shift)
    0, ' ', 0, 0, 0, 0, 0, 0, // 0x38-0x3F (0x38 = alt, 0x39 = space)
};

pub const Keyboard = struct {
    shift_pressed: bool = false,
    ctrl_pressed: bool = false,
    alt_pressed: bool = false,
    windows_pressed: bool = false,
    extended_key: bool = false,

    pub fn init() Keyboard {
        return Keyboard{};
    }

    pub fn readScancode(self: *Keyboard) ?KeyEvent {
        if (!self.isDataAvailable()) return null;

        const scancode = self.readByte();
        const pressed = (scancode & 0x80) == 0;
        const key_code = scancode & 0x7F;

        // Handle extended key sequence (0xE0)
        if (scancode == 0xE0) {
            self.extended_key = true;
            return null; // Wait for next byte
        }

        const is_extended = self.extended_key;
        if (is_extended) {
            self.extended_key = false;
        }

        switch (key_code) {
            @intFromEnum(Key.LeftShift), @intFromEnum(Key.RightShift) => {
                self.shift_pressed = pressed;
                return KeyEvent{ .scancode = scancode, .character = null, .pressed = pressed };
            },
            @intFromEnum(Key.LeftCtrl) => {
                self.ctrl_pressed = pressed;
                return KeyEvent{ .scancode = scancode, .character = null, .pressed = pressed };
            },
            @intFromEnum(Key.LeftAlt) => {
                self.alt_pressed = pressed;
                return KeyEvent{ .scancode = scancode, .character = null, .pressed = pressed };
            },
            @intFromEnum(Key.F1), @intFromEnum(Key.F2), @intFromEnum(Key.F3), @intFromEnum(Key.F4) => {
                // Always return F-keys, even on release for screen manager to handle
                return KeyEvent{ .scancode = scancode, .character = null, .pressed = pressed };
            },
            @intFromEnum(Key.Escape) => {
                return KeyEvent{ .scancode = scancode, .character = 27, .pressed = pressed }; // Return ESC character
            },
            @intFromEnum(Key.ArrowUp) => {
                if (is_extended and pressed) {
                    return KeyEvent{ .scancode = scancode, .character = null, .pressed = pressed, .special = .ArrowUp };
                }
                return KeyEvent{ .scancode = scancode, .character = null, .pressed = pressed };
            },
            @intFromEnum(Key.ArrowDown) => {
                if (is_extended and pressed) {
                    return KeyEvent{ .scancode = scancode, .character = null, .pressed = pressed, .special = .ArrowDown };
                }
                return KeyEvent{ .scancode = scancode, .character = null, .pressed = pressed };
            },
            @intFromEnum(Key.ArrowLeft) => {
                if (is_extended and pressed) {
                    return KeyEvent{ .scancode = scancode, .character = null, .pressed = pressed, .special = .ArrowLeft };
                }
                return KeyEvent{ .scancode = scancode, .character = null, .pressed = pressed };
            },
            @intFromEnum(Key.ArrowRight) => {
                if (is_extended and pressed) {
                    return KeyEvent{ .scancode = scancode, .character = null, .pressed = pressed, .special = .ArrowRight };
                }
                return KeyEvent{ .scancode = scancode, .character = null, .pressed = pressed };
            },
            @intFromEnum(Key.LeftWindows) => {
                if (is_extended) {
                    self.windows_pressed = pressed;
                    if (pressed) {
                        return KeyEvent{ .scancode = scancode, .character = null, .pressed = pressed, .special = .WindowsKey };
                    }
                }
                return KeyEvent{ .scancode = scancode, .character = null, .pressed = pressed };
            },
            @intFromEnum(Key.RightWindows) => {
                if (is_extended) {
                    self.windows_pressed = pressed;
                    if (pressed) {
                        return KeyEvent{ .scancode = scancode, .character = null, .pressed = pressed, .special = .WindowsKey };
                    }
                }
                return KeyEvent{ .scancode = scancode, .character = null, .pressed = pressed };
            },
            else => {
                if (!pressed) return KeyEvent{ .scancode = scancode, .character = null, .pressed = pressed };

                var character: ?u8 = null;
                if (key_code < scancode_to_char.len) {
                    var base_char = scancode_to_char[key_code];
                    if (base_char != 0) {
                        if (self.shift_pressed and base_char >= 'a' and base_char <= 'z') {
                            base_char = base_char - 'a' + 'A';
                        }
                        character = base_char;
                    }
                }

                return KeyEvent{ .scancode = scancode, .character = character, .pressed = pressed };
            },
        }
    }

    fn isDataAvailable(self: *Keyboard) bool {
        _ = self;
        return (inb(KEYBOARD_STATUS_PORT) & 1) != 0;
    }

    fn readByte(self: *Keyboard) u8 {
        _ = self;
        return inb(KEYBOARD_DATA_PORT);
    }
};

fn inb(port: u16) u8 {
    return asm volatile ("inb %[port], %[result]"
        : [result] "={al}" (-> u8),
        : [port] "N{dx}" (port),
    );
}
