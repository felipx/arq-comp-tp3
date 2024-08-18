# Toolchain and flags
CC = riscv64-unknown-elf-gcc
AS = riscv64-unknown-elf-as
LD = riscv64-unknown-elf-ld
OBJDUMP = riscv64-unknown-elf-objdump
OBJCOPY = riscv64-unknown-elf-objcopy
CFLAGS = -march=rv32i -mabi=ilp32 -nostartfiles -nostdlib -ffreestanding
ASFLAGS = -march=rv32i -mabi=ilp32
LDFLAGS = -march=rv32i -melf32lriscv -Tlinker.ld

# Targets
TARGET = program
ENTRY = entry.o
SRCS = main.c
OBJS = $(ENTRY) $(SRCS:.c=.o)

# Default target
all: $(TARGET).elf $(TARGET).bin $(TARGET).disasm

# Compile C files
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Assemble the entry file
$(ENTRY): entry.s
	$(AS) $(ASFLAGS) $< -o $@

# Link the object files
$(TARGET).elf: $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $^

# Generate a binary file
$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $< $@

# Generate a disassembly file
$(TARGET).disasm: $(TARGET).elf
	$(OBJDUMP) -d $< > $@

# Clean up
clean:
	rm -f $(OBJS) $(TARGET).elf $(TARGET).bin $(TARGET).disasm
