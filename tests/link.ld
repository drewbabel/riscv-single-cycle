ENTRY(_start)
MEMORY { imem (rx) : ORIGIN = 0x00000000, LENGTH = 256 }
SECTIONS {
    .text : { *(.text*) } > imem
}
