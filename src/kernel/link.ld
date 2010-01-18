OUTPUT_FORMAT("pe-i386")
ENTRY(_k_main)
SECTIONS {
    . = 0x9000;
    .text : { *(.text) }
    .data : { *(.data) }
    .bss : { *(.bss) }
}
