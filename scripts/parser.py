# The following script reads a simple RISC-V assembly text file, 
# converts each instruction to binary, and writes the binary 
# instructions to a .bin file, without the need to install/use
# an risc-v assembler/compiler/toolchain

import sys
import os
import struct

# Instruction set for RISC-V
opcode_map = {
    'lui':   ('0110111', 'U'),
    'auipc': ('0010111', 'U'),
    'jal':   ('1101111', 'J'),
    'jalr':  ('1100111', 'I', '000'),
    'beq':   ('1100011', 'B', '000'),
    'bne':   ('1100011', 'B', '001'),
    'blt':   ('1100011', 'B', '100'),
    'bge':   ('1100011', 'B', '101'),
    'bltu':  ('1100011', 'B', '110'),
    'bgeu':  ('1100011', 'B', '111'),
    'lb':    ('0000011', 'I', '000'),
    'lh':    ('0000011', 'I', '001'),
    'lw':    ('0000011', 'I', '010'),
    'lbu':   ('0000011', 'I', '100'),
    'lhu':   ('0000011', 'I', '101'),
    'sb':    ('0100011', 'S', '000'),
    'sh':    ('0100011', 'S', '001'),
    'sw':    ('0100011', 'S', '010'),
    'addi':  ('0010011', 'I', '000'),
    'slti':  ('0010011', 'I', '010'),
    'sltiu': ('0010011', 'I', '011'),
    'xori':  ('0010011', 'I', '100'),
    'ori':   ('0010011', 'I', '110'),
    'andi':  ('0010011', 'I', '111'),
    'slli':  ('0010011', 'I', '001', '0000000'),
    'srli':  ('0010011', 'I', '101', '0000000'),
    'srai':  ('0010011', 'I', '101', '0100000'),
    'add':   ('0110011', 'R', '000', '0000000'),
    'sub':   ('0110011', 'R', '000', '0100000'),
    'sll':   ('0110011', 'R', '001', '0000000'),
    'slt':   ('0110011', 'R', '010', '0000000'),
    'sltu':  ('0110011', 'R', '011', '0000000'),
    'xor':   ('0110011', 'R', '100', '0000000'),
    'srl':   ('0110011', 'R', '101', '0000000'),
    'sra':   ('0110011', 'R', '101', '0100000'),
    'or':    ('0110011', 'R', '110', '0000000'),
    'and':   ('0110011', 'R', '111', '0000000'),
}

# Register File Map
register_map = {
    'x0': 0, 'x1': 1, 'x2': 2, 'x3': 3, 'x4': 4, 'x5': 5, 'x6': 6, 'x7': 7,
    'x8': 8, 'x9': 9, 'x10': 10, 'x11': 11, 'x12': 12, 'x13': 13, 'x14': 14, 'x15': 15,
    'x16': 16, 'x17': 17, 'x18': 18, 'x19': 19, 'x20': 20, 'x21': 21, 'x22': 22, 'x23': 23,
    'x24': 24, 'x25': 25, 'x26': 26, 'x27': 27, 'x28': 28, 'x29': 29, 'x30': 30, 'x31': 31,
}

def parse_instruction(line: str) -> tuple[str, str, str, str]:
    """
    Parses a single line of RISC-V assembly code and returns a tuple representing the instruction.

    Args:
        line (str): A line of RISC-V assembly code (e.g., 'addi x1, x2, 10').

    Returns:
        tuple: A tuple containing the instruction and its operands.
               For example: ('addi', 'x1', 'x2', '10').

        None: If the instruction is not recognized.
    """
    parts = line.replace(',', '').split()
    instr = parts[0]
    if instr == 'jalr':
        # Handling of 'jalr' instruction
        rd = parts[1]
        imm, rs1 = parts[2].split('(')  # Split immediate and register
        rs1 = rs1.rstrip(')')           # Remove closing parenthesis from rs1
        return (instr, rd, rs1, imm)

    if instr in opcode_map:
        fmt = opcode_map[instr][1]
        if fmt == 'R':
            # R-type: Parse rd, rs1, rs2
            rd = parts[1]
            rs1 = parts[2]
            rs2 = parts[3]
            return (instr, rd, rs1, rs2)
        elif fmt == 'I':
            # I-type: Parse rd, rs1, imm
            rd = parts[1]
            rs1 = parts[2]
            imm = parts[3]
            return (instr, rd, rs1, imm)
        elif fmt == 'S':
            # S-type: Parse rs2, imm, rs1
            rs2 = parts[1]
            imm, rs1 = parts[2].split('(')  # Split immediate and register
            rs1 = rs1.rstrip(')')           # Remove closing parenthesis from rs1
            return (instr, rs2, rs1, imm)
        elif fmt == 'B':
            # B-type: Parse rs1, rs2, imm
            rs1 = parts[1]
            rs2 = parts[2]
            imm = parts[3]
            return (instr, rs1, rs2, imm)
        elif fmt == 'U' or fmt == 'J':
            # U-type or J-type: Parse rd, imm
            rd = parts[1]
            imm = parts[2]
            return (instr, rd, imm)
    return None                      # Return None if the instruction is not recognized

def convert_to_binary(instr_tuple: tuple[str, str, str, str]) -> int:
    """
    Converts a parsed RISC-V instruction tuple into its binary representation.

    Args:
        instr_tuple (tuple): A tuple representing a RISC-V instruction and its operands.

    Returns:
        int: The binary representation of the instruction as a 32-bit integer.
    """

    instr, *operands = instr_tuple                            # Unpack the instruction tuple
    opcode, fmt = opcode_map[instr][0], opcode_map[instr][1]  # Get the opcode and format
    
    if fmt == 'R':
         # R-format: funct7 | rs2 | rs1 | funct3 | rd | opcode
        rd = f"{register_map[operands[0]]:05b}"
        rs1 = f"{register_map[operands[1]]:05b}"
        rs2 = f"{register_map[operands[2]]:05b}"
        funct3 = opcode_map[instr][2]
        funct7 = opcode_map[instr][3]
        binary_instr = f"{funct7}{rs2}{rs1}{funct3}{rd}{opcode}"
        
    elif fmt == 'I':
        # I-format: immediate | rs1 | funct3 | rd | opcode
        rd = f"{register_map[operands[0]]:05b}"
        rs1 = f"{register_map[operands[1]]:05b}"
        imm = f"{int(operands[2], 0) & 0xfff:012b}"      # Mask the immediate to 12 bits
        funct3 = opcode_map[instr][2]
        binary_instr = f"{imm}{rs1}{funct3}{rd}{opcode}"
        
    elif fmt == 'S':
        # S-format: immediate[11:5] | rs2 | rs1 | funct3 | immediate[4:0] | opcode
        rs1 = f"{register_map[operands[1]]:05b}"
        rs2 = f"{register_map[operands[0]]:05b}"
        imm = int(operands[2], 0) & 0xfff         # Mask the immediate to 12 bits
        imm_4_0 = f"{imm & 0x1f:05b}"             # Extract the lower 5 bits
        imm_11_5 = f"{(imm >> 5) & 0x7f:07b}"     # Extract the upper 7 bits
        funct3 = opcode_map[instr][2]
        binary_instr = f"{imm_11_5}{rs2}{rs1}{funct3}{imm_4_0}{opcode}"
        
    elif fmt == 'B':
        # B-format: immediate[12] | immediate[10:5] | rs2 | rs1 | funct3 | immediate[4:1] | immediate[11] | opcode
        rs1 = f"{register_map[operands[0]]:05b}"
        rs2 = f"{register_map[operands[1]]:05b}"
        imm = int(operands[2], 0) & 0x1fff
        imm_11 = f"{(imm >> 11) & 0x1:01b}"
        imm_10_5 = f"{(imm >> 5) & 0x3f:06b}"
        imm_4_1 = f"{(imm >> 1) & 0xf:04b}"
        imm_12 = f"{(imm >> 12) & 0x1:01b}"
        funct3 = opcode_map[instr][2]
        binary_instr = f"{imm_12}{imm_10_5}{rs2}{rs1}{funct3}{imm_4_1}{imm_11}{opcode}"
        
    elif fmt == 'U':
        # U-format: immediate[31:12] | rd | opcode
        rd = f"{register_map[operands[0]]:05b}"
        imm = f"{int(operands[1], 0) & 0xfffff:020b}"
        binary_instr = f"{imm}{rd}{opcode}"
    
    elif fmt == 'J':
        # J-format: immediate[20] | immediate[10:1] | immediate[11] | immediate[19:12] | rd | opcode
        rd = f"{register_map[operands[0]]:05b}"
        imm = int(operands[1], 0) & 0x1fffff      # Mask the immediate to 21 bits
        imm_19_12 = f"{(imm >> 12) & 0xff:08b}"   # Extract bits 19:12
        imm_11 = f"{(imm >> 11) & 0x1:01b}"       # Extract bit 11
        imm_10_1 = f"{(imm >> 1) & 0x3ff:010b}"   # Extract bits 10:1
        imm_20 = f"{(imm >> 20) & 0x1:01b}"       # Extract bit 20
        binary_instr = f"{imm_20}{imm_10_1}{imm_11}{imm_19_12}{rd}{opcode}"
    
    return int(binary_instr, 2)

def main():
    """
    Reads a RISC-V assembly text file, converts each instruction to binary,
    and writes the binary instructions to a .bin file.

    Args:
        input_file (str): The name of the input text file containing RISC-V assembly code.
    """

    if len(sys.argv) != 2:
        print("Usage: python script.py <input_file>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = os.path.splitext(input_file)[0] + ".bin"

    with open(input_file, 'r') as infile, open(output_file, 'wb') as outfile:
        for line in infile:
            line = line.strip()
            if line:  # Skip empty lines
                instr_tuple = parse_instruction(line)
                if instr_tuple:
                    binary_instr = convert_to_binary(instr_tuple)
                    outfile.write(struct.pack('<I', binary_instr))

if __name__ == "__main__":
    main()
