const Gdt = @This();

const GdtEntry = packed struct {};

const GdtPtr = packed struct {};

const gdt: GdtEntry[3] = undefined;
const gdt_ptr: GdtPtr = undefined;
