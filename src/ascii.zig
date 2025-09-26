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
