
OUTPUT_ARCH(riscv)
ENTRY(_start)

/* Memory Regions */
MEMORY
{
    /* 1KiB Instruction Memory starting at 0x0 */
    instr_mem (rx) : ORIGIN = 0x0, LENGTH = 1K

    /* 1KiB Data Memory starting at 0x0 */
    data_mem (rw) : ORIGIN = 0x0, LENGTH = 1K
}

/* Sections */
SECTIONS
{
    /* Code and read-only data into the instruction memory */
    .text :
    {
        _start = .;
        *(.text)            /* All .text sections from input files */
        *(.rodata*)         /* Read-only data */
        *(.srodata*)        /* Small read-only data */
    } > instr_mem

    /* Initialized data into the data memory */
    .data :
    {
        _data = .;
        *(.data)            /* All .data sections from input files */
        *(.sdata)           /* Small initialized data */
        . = ALIGN(4);
        _edata = .;
    } > data_mem

    /* Uninitialized data (BSS) into the data memory */
    .bss :
    {
        _bss = .;
        *(.bss)
        *(COMMON)
        . = ALIGN(4);
        _ebss = .;
    } > data_mem

    /* Stack pointer will be set in the startup assembly */
    . = ALIGN(4);
    _end = .;
}
