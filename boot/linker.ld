ENTRY(_start)
 
SECTIONS {
    . = 2M;

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