ENTRY(_start)
 
SECTIONS {
    . = 0x00000800;
    .gdt : {
        KEEP(*(.gdt))
    }

    . = 0x200000; /* 1MB */
    .text : ALIGN(4K) {
        /* We need to specify KEEP to prevent the linker from garbage-collecting the multiboot section. */
        KEEP(*(.multiboot))
        *(.text*)    /* * after text catches .text.unlikely etc */
    }
 
    .rodata : ALIGN(4K) {
        *(.rodata*)
    }

    .data : ALIGN(4K) {
        *(.data*)
    }

    .bss : ALIGN(4K) {
        *(COMMON)
        *(.bss*)
    }

    /* Discard everything else */
    /DISCARD/ : {
        *(.comment)
        *(.eh_frame*)
        *(.debug*)
    }

}