const std = @import("std");

// VGA constants
pub const VGA_BUFFER = @as([*]volatile u16, @ptrFromInt(0xB8000));
pub const VGA_WIDTH = 80;
pub const VGA_HEIGHT = 25;

// VGA hardware I/O functions
fn outb(port: u16, value: u8) void {
    asm volatile ("outb %[value], %[port]"
        :
        : [value] "{al}" (value),
          [port] "N{dx}" (port),
    );
}

// Basic VGA display functions
pub fn clearScreen(bg_color: u8) void {
    var i: usize = 0;
    while (i < VGA_WIDTH * VGA_HEIGHT) : (i += 1) {
        VGA_BUFFER[i] = @as(u16, ' ') | (@as(u16, bg_color) << 8);
    }
}

pub fn putChar(x: usize, y: usize, char: u8, color: u8) void {
    if (x >= VGA_WIDTH or y >= VGA_HEIGHT) return;
    const index = y * VGA_WIDTH + x;
    VGA_BUFFER[index] = @as(u16, char) | (@as(u16, color) << 8);
}

/// Only the Y coordinate is specified, X is calculated to center the text
pub fn putStringCentered(y: usize, text: []const u8, color: u8) void {
    const x = (VGA_WIDTH - text.len) / 2;
    putString(x, y, text, color);
}

pub fn putString(x: usize, y: usize, text: []const u8, color: u8) void {
    for (text, 0..) |char, i| {
        if (x + i >= VGA_WIDTH) break;
        putChar(x + i, y, char, color);
    }
}

// VGA cursor control functions
pub fn setCursorPosition(x: usize, y: usize) void {
    const pos: u16 = @intCast(y * VGA_WIDTH + x);

    // Set cursor position using VGA registers
    outb(0x3D4, 0x0F); // Cursor location low byte register
    outb(0x3D5, @intCast(pos & 0xFF));
    outb(0x3D4, 0x0E); // Cursor location high byte register
    outb(0x3D5, @intCast((pos >> 8) & 0xFF));
}

pub fn hideCursor() void {
    // Disable cursor by setting cursor start register bit 5
    outb(0x3D4, 0x0A); // Cursor start register
    outb(0x3D5, 0x20); // Bit 5 set = cursor disabled
}

pub fn showCursor() void {
    // Enable cursor by setting cursor shape
    outb(0x3D4, 0x0A); // Cursor start register
    outb(0x3D5, 0x0D); // Cursor start line (13)
    outb(0x3D4, 0x0B); // Cursor end register
    outb(0x3D5, 0x0F); // Cursor end line (15)
}
