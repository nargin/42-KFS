const std = @import("std");
const vga = @import("../drivers/vga.zig");
const screens = @import("./screens.zig");
const UIContext = @import("context.zig").UIContext;
const SpecialKey = @import("../drivers/keyboard.zig").SpecialKey;
const Key = @import("../drivers/keyboard.zig").Key;
const ASCII = @import("../drivers/keyboard.zig").ASCII;
const power = @import("../panic.zig");

pub fn getPrompt(ctx: *UIContext, buffer: []u8) []const u8 {
    var prefix: []const u8 = undefined;
    switch (ctx.exit_code) {
        -1 | 0 => prefix = "> ",
        1 => prefix = "! > ",
        127 => prefix = "?:127 > ",
        else => prefix = "? > ",
    }

    @memcpy(buffer[0..prefix.len], prefix);
    return buffer[0..prefix.len];
}

const INPUT_ROW = 24;
const SEPARATOR_ROW = 23;
const MAX_INPUT_BUFFER_SIZE = 255;

pub fn strcmp(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    for (a, 0..a.len) |c, i| {
        if (c != b[i]) return false;
    }
    return true;
}

const Command = enum {
    clear,
    echo,
    halt,
    memmap,
    stack,
    trace,
    reboot,
    shutdown,
    panic,
    help,
};

pub fn handleCommand(ctx: *UIContext, command: []const u8) i8 {
    // 1. Convert string to enum
    const cmd = std.meta.stringToEnum(Command, command) orelse {
        ctx.main_output.addLine("Unknown command. Type /help for a list of commands.");
        return 127;
    };

    // 2. Switch on the resulting enum
    switch (cmd) {
        .clear => ctx.main_output.clear(),
        .echo => {
            ctx.main_output.addLine(ctx.main_input.data[0..ctx.main_input.length]);
        },
        .halt => power.halt(),
        .memmap => printMemoryMap(ctx),
        .stack => printStack(ctx),
        .trace => printStackTrace(ctx),
        .reboot => power.reboot(),
        .shutdown => power.shutdown(),
        .panic => power.panic("Panic command invoked"),
        .help => {
            ctx.main_output.addLine("Commands:");
            ctx.main_output.addLine("  clear  memmap  stack  trace");
            ctx.main_output.addLine("  halt   reboot  shutdown  panic");
            return 0;
        },
    }
    return 0;
}

pub fn drawInput(ctx: *UIContext) void {
    vga.putString(0, SEPARATOR_ROW, "\xCD" ** vga.VGA_WIDTH, 0x1E);

    var prompt_buf: [64]u8 = undefined;

    const prompt = getPrompt(ctx, &prompt_buf);
    vga.putString(0, INPUT_ROW, prompt, 0x0B);

    var col: usize = prompt.len;
    while (col < vga.VGA_WIDTH) : (col += 1) {
        vga.putChar(col, INPUT_ROW, ' ', 0x07);
    }

    if (ctx.main_input.length > 0) {
        const available_width = vga.VGA_WIDTH - prompt.len;
        const display_len = @min(ctx.main_input.length, available_width);
        vga.putString(prompt.len, INPUT_ROW, ctx.main_input.data[0..display_len], 0x0F);
    }

    const cursor_pos = @min(prompt.len + ctx.main_input.cursor, vga.VGA_WIDTH - 1);
    vga.setCursorPosition(cursor_pos, INPUT_ROW);
}

pub fn processInput(ctx: *UIContext) void {
    if (ctx.main_input.length == 0) return;

    var echo: [80]u8 = [_]u8{0} ** 80;
    const prefix = "> ";
    @memcpy(echo[0..prefix.len], prefix);
    const copy_len = @min(ctx.main_input.length, 80 - prefix.len);
    @memcpy(echo[prefix.len .. prefix.len + copy_len], ctx.main_input.data[0..copy_len]);
    ctx.main_output.addLine(echo[0 .. prefix.len + copy_len]);

    ctx.exit_code = handleCommand(ctx, ctx.main_input.data[0..ctx.main_input.length]);

    ctx.main_input.clear();
    screens.renderScreen(ctx);
    return;
}

pub fn handleChar(ctx: *UIContext, char: u8) void {
    if (char == ASCII.ESCAPE) {
        ctx.main_input.clear();
        drawInput(ctx);
        return;
    }

    switch (char) {
        ASCII.BACKSPACE => {
            ctx.main_input.deleteChar();
        },
        ASCII.ENTER => {},
        else => {
            const prompt_len = 4; // "> " + ": "
            const available_input_chars = vga.VGA_WIDTH - prompt_len;
            const max_chars = @min(MAX_INPUT_BUFFER_SIZE, available_input_chars);
            if (ASCII.isPrintable(char)) {
                ctx.main_input.insertChar(char, max_chars);
            }
        },
    }
}

pub fn handleKeyEvent(ctx: *UIContext, key_event: anytype) void {
    if (!key_event.pressed) return;

    if (key_event.special) |special_key| {
        switch (special_key) {
            .ArrowLeft => {
                if (ctx.main_input.cursor > 0) ctx.main_input.cursor -= 1;
            },
            .ArrowRight => {
                if (ctx.main_input.cursor < ctx.main_input.length) ctx.main_input.cursor += 1;
            },
            .ArrowUp => ctx.main_output.scrollUp(),
            .ArrowDown => ctx.main_output.scrollDown(),
            else => {},
        }
        screens.renderScreen(ctx);
        drawInput(ctx);
        return;
    }

    if (key_event.character) |char| {
        handleChar(ctx, char);
        screens.renderScreen(ctx);
        drawInput(ctx);

        if (char == '\n') {
            processInput(ctx);
            drawInput(ctx);
        }
    }
}

fn printMemoryMap(ctx: *UIContext) void {
    const start: u32 = 0x00200000; // kernel load address
    const rows = 20;

    var row: u32 = 0;
    while (row < rows) : (row += 1) {
        const addr = start + row * 16;
        const bytes: [*]const u8 = @ptrFromInt(addr);
        var line: [80]u8 = [_]u8{' '} ** 80;
        var p: usize = 0;

        const hdr = std.fmt.bufPrint(line[p..], "0x{X:0>8}  ", .{addr}) catch continue;
        p += hdr.len;

        for (0..16) |i| {
            const h = std.fmt.bufPrint(line[p..], "{X:0>2}", .{bytes[i]}) catch continue;
            p += h.len;
            if (i < 15) {
                line[p] = ' ';
                p += 1;
            }
        }

        line[p] = ' ';
        p += 1;
        line[p] = '|';
        p += 1;
        for (0..16) |i| {
            const b = bytes[i];
            line[p] = if (b >= 32 and b < 127) b else '.';
            p += 1;
        }
        line[p] = '|';
        p += 1;

        ctx.main_output.addLine(line[0..p]);
    }
}

fn printStack(ctx: *UIContext) void {
    var esp: u32 = 0;
    var ebp: u32 = 0;
    asm volatile ("movl %%esp, %[esp]"
        : [esp] "=r" (esp),
    );
    asm volatile ("movl %%ebp, %[ebp]"
        : [ebp] "=r" (ebp),
    );

    var line: [80]u8 = undefined;
    const hdr = std.fmt.bufPrint(&line, "ESP=0x{X:0>8}  EBP=0x{X:0>8}", .{ esp, ebp }) catch return;
    ctx.main_output.addLine(hdr);

    var addr = esp;
    while (addr <= ebp and addr + 3 <= ebp) : (addr += 4) {
        const val: *const u32 = @ptrFromInt(addr);
        const l = std.fmt.bufPrint(&line, "  [0x{X:0>8}] = 0x{X:0>8}", .{ addr, val.* }) catch continue;
        ctx.main_output.addLine(l);
    }
}

fn printStackTrace(ctx: *UIContext) void {
    var ebp: u32 = 0;
    asm volatile ("movl %%ebp, %[ebp]"
        : [ebp] "=r" (ebp),
    );

    ctx.main_output.addLine("--- stack trace ---");
    var line: [80]u8 = undefined;
    var frame: u32 = 0;
    while (ebp != 0 and frame < 16) : (frame += 1) {
        const ret: u32 = @as(*const u32, @ptrFromInt(ebp + 4)).*;
        const l = std.fmt.bufPrint(&line, "  #{d}  ebp=0x{X:0>8}  ret=0x{X:0>8}", .{ frame, ebp, ret }) catch break;
        ctx.main_output.addLine(l);
        const next: u32 = @as(*const u32, @ptrFromInt(ebp)).*;
        if (next <= ebp) break;
        ebp = next;
    }
    ctx.main_output.addLine("-------------------");
}
