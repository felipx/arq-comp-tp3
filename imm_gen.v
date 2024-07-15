module imm_gen
#(
    parameter DATA_WIDTH = 32            //! Data width of the immediate
) (
    output reg [DATA_WIDTH - 1 : 0] o_imm  , //! Immediate output
    input      [DATA_WIDTH - 1 : 0] i_instr  //! Instruction input
);

    // Instruction format encoding
    localparam I_TYPE_1 = 7'b0010011;  //! Opcode for I-Type arithmetic instructions (e.g., ADDI)
    localparam I_TYPE_2 = 7'b0000011;  //! Opcode for I-Type load instructions (e.g., LW)
    localparam I_TYPE_3 = 7'b1100111;  //! Opcode for I-Type JALR
    localparam I_TYPE_4 = 7'b1110011;  //! Opcode for I-Type System instructions (e.g., EBREAK)
    localparam S_TYPE   = 7'b0100011;  //! Opcode for S-Type store instructions (e.g., SW)
    localparam B_TYPE   = 7'b1100011;  //! Opcode for B-Type branch instructions (e.g., BEQ)
    localparam U_TYPE_1 = 7'b0110111;  //! Opcode for U-Type instructions (e.g., LUI)
    localparam U_TYPE_2 = 7'b0010111;  //! Opcode for U-Type instructions (e.g., AUIPC)
    localparam J_TYPE   = 7'b1101111;  //! Opcode for J-Type instructions (e.g., JAL)

    always @(*) begin
        case (i_instr[6:0])
            I_TYPE_1, I_TYPE_2, I_TYPE_3, I_TYPE_4: begin
                // I-Type immediate: sign-extend from bits 31:20
                o_imm = {{20{i_instr[31]}}, i_instr[31:20]};
            end
            S_TYPE: begin
                // S-Type immediate: sign-extend from bits 31:25 and 11:7
                o_imm = {{20{i_instr[31]}}, i_instr[31:25], i_instr[11:7]};
            end
            B_TYPE: begin
                // B-Type immediate: sign-extend from bits 31, 7, 30:25, 11:8, shifted left by 1
                o_imm = {{19{i_instr[31]}}, i_instr[31], i_instr[7], i_instr[30:25], i_instr[11:8], 1'b0};
            end
            U_TYPE_1, U_TYPE_2: begin
                // U-Type immediate: upper 20 bits, lower 12 bits are zero
                o_imm = {i_instr[31:12], 12'b0};
            end
            J_TYPE: begin
                // J-Type immediate: sign-extend from bits 31, 19:12, 20, 30:21, shifted left by 1
                o_imm = {{11{i_instr[31]}}, i_instr[31], i_instr[19:12], i_instr[20], i_instr[30:21], 1'b0};
            end
            default: begin
                // Default case if instruction doesn't match known opcodes
                o_imm = 32'b0;
            end
        endcase
    end

endmodule