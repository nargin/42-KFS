const IDT = @This();

const IdtEntry = packed struct {
    isr_low: u16,
    kernel_cs: u16,
    ist: u8,
    attributes: u8,
    isr_mid: u16,
    isr_high: u32,
    reserved: u32,
};

const Idtr = packed struct {
    limit: u16,
    base: u64,
};

pub const idt: IdtEntry align(256) = undefined;
pub const idtr: Idtr = undefined;
