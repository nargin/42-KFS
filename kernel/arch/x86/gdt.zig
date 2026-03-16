const Gdt = @This();

const GdtEntry = packed struct {
    limit_low: u16 = 0,
    base_low: u16 = 0,
    base_mid: u8 = 0,
    access: u8 = 0, // present, ring, type flags
    limit_high: u4 = 0,
    flags: u4 = 0, // granularity, 32-bit, etc.
    base_high: u8 = 0,
};

const GdtPtr = packed struct {
    limit: u16,
    base: u32,
};

var gdt: [3]GdtEntry = undefined;
var gdt_ptr: GdtPtr = undefined;

fn makeEntry(base: u32, limit: u20, access: u8, flags: u4) GdtEntry {
    return GdtEntry{
        .limit_low = @truncate(limit),
        .limit_high = @truncate(limit >> 16),
        .base_low = @truncate(base),
        .base_mid = @truncate(base >> 16),
        .base_high = @truncate(base >> 24),
        .access = access,
        .flags = flags,
    };
}

pub fn init() void {
    // src: https://wiki.osdev.org/GDT_Tutorial (64 Bit version)
    gdt[0] = makeEntry(0, 0x0, 0x0, 0x0); // Null Descriptor
    gdt[1] = makeEntry(0, 0xFFFFF, 0x9A, 0xC); // Kernel Mode Code Segment
    gdt[2] = makeEntry(0, 0xFFFFF, 0x92, 0xC);

    // Access byte values:
    // - 0x9A = 1001 1010 → present, ring 0, code, executable, readable
    // - 0x92 = 1001 0010 → present, ring 0, data, readable, writable

    // user space
    // gdt[3] = makeEntry(0, 0xFFFFF, 0xF2, 0xC);
    // gdt[4] = makeEntry(0, 0xFFFFF, 0xFA, 0xA);
    // gdt[5] = makeEntry(0, 0xFFFFF, 0x89, 0x0);

    gdt_ptr = .{
        .limit = @sizeOf(@TypeOf(gdt)) - 1,
        .base = @intFromPtr(&gdt),
    };

    asm volatile (
        \\ lgdt (%[ptr])
        \\ mov $0x10, %%ax       // 0x10 = index 2 (data segment)
        \\ mov %%ax, %%ds
        \\ mov %%ax, %%es
        \\ mov %%ax, %%fs
        \\ mov %%ax, %%gs
        \\ mov %%ax, %%ss
        \\ push $0x08            // 0x08 = index 1 (code segment)
        \\ push $.flush
        \\ lret                  // far return -> reloads CS
        \\ .flush:
        :
        : [ptr] "r" (&gdt_ptr),
        : .{ .eax = true, .memory = true });
}
