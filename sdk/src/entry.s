.section .text
.global _start

_start:
    # Set the stack pointer (sp) and global pointer (gp)
    
    # The stack grows downwards, so we set the stack pointer to the top of the data memory.
    # Data memory starts at 0x0 and is 1KiB (1024 bytes), so we set the stack pointer to 0x400 (1024).
    lui sp, 0x0      # Load upper immediate (0x000) to sp
    addi sp, sp, 1024  # Set sp to the top of data memory (0x400)

    # Set the global pointer. The global pointer is typically set to the middle of the data memory to allow 
    # easy access to both global variables and the stack. Since the data memory is 1KiB, the middle is 0x200.
    lui gp, 0x0      # Load upper immediate (0x000) to gp
    addi gp, gp, 512   # Set gp to the middle of data memory (0x200)
    
    # Call the main function
    call main

    # Exit the program
    #li a7, 10       # Syscall number for exit
    #ecall           # Make the syscall

