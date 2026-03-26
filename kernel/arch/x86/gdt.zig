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

export var gdt: [7]GdtEntry linksection(".gdt") = undefined; // linked to 0x00000800
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
    // Kernel ---
    gdt[1] = makeEntry(0, 0xFFFFF, 0x9A, 0xC); // Code Segment
    gdt[2] = makeEntry(0, 0xFFFFF, 0x92, 0xC); // Data
    gdt[3] = makeEntry(0, 0xFFFF, 0x92, 0xC); // Stack
    // User space
    gdt[4] = makeEntry(0, 0xFFFF, 0xFA, 0xC); // user code
    gdt[5] = makeEntry(0, 0xFFFF, 0xF2, 0xC); // user data
    gdt[6] = makeEntry(0, 0xFFFF, 0xF2, 0xC); // user stack

    // Access byte values:
    //   - 0x9A = 1001 1010 → present, ring 0, code segment, executable, readable
    //   - 0x92 = 1001 0010 → present, ring 0, data segment, writable (used for data and stack)
    //   - 0xFA = 1111 1010 → present, ring 3, code segment, executable, readable
    //   - 0xF2 = 1111 0010 → present, ring 3, data segment, writable

    gdt_ptr = .{
        .limit = @sizeOf(@TypeOf(gdt)) - 1, // might have to change cause of fix sized smtg idk...
        .base = @intFromPtr(&gdt),
    };

    asm volatile (
        \\ lgdt (%[ptr])
        \\ mov $0x18, %ax   //kernel stack selector (index 3)
        \\ mov %ax, %ss     // SS = kernel stack segment
        \\ mov $0x10, %%ax  // 0x10 = index 2 (data segment)
        \\ mov %%ax, %%ds   // DS = kernel data
        \\ mov %%ax, %%es   // ES = kernel data  
        \\ mov %%ax, %%fs   // FS = kernel data
        \\ mov %%ax, %%gs   // GS = kernel data
        \\ push $0x08       // push kernel code selector onto stack 
        \\ push $.flush     // 
        \\ lret
        \\ .flush:
        :
        : [ptr] "r" (&gdt_ptr),
        : .{ .eax = true, .memory = true });
}
