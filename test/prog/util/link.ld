OUTPUT_ARCH(riscv)
ENTRY(_start)

/* DRAM_WORDS = 1024 words = 4 KB per memory region.
   Update LENGTH here if DRAM_WORDS changes in takefive_pkg.sv. */
MEMORY {
    IMEM (rx) : ORIGIN = 0x00000000, LENGTH = 4K
    DMEM (rw) : ORIGIN = 0x80000000, LENGTH = 4K
}

SECTIONS {
    .text : {
        . = 0;
        KEEP(*(.text.start))
        *(.text*)
    } > IMEM
    .rodata : { *(.rodata*) } > DMEM
    .data   : { *(.data*)   } > DMEM
    .bss    : {
        __bss_start = .;
        *(.bss*) *(COMMON)
        __bss_end = .;
    } > DMEM
}
