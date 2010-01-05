OUTPUT_FORMAT("pe-i386")
ENTRY(start)
SECTIONS {
    . = 0x0;
    .text : { *(.text) }
    .data : { *(.data) }
    .bss : { *(.bss) }
}
