//! @title ALU CONTROL UNIT
//! @file alu_ctrl_unit.v
//! @author Felipe Montero Bruni
//! @date 07-2024
//! @version 0.1

module alu_ctrl_unit
#()
(
    // Output
    output reg [4 : 0] o_alu_op,  //! ALU operation control signal
                                            
    // Inputs                               
    input wire [1 : 0] i_alu_op,  //! ALUOp from Control Unit
    input wire [6 : 0] i_funct7,  //! funct7 field from instruction
    input wire [2 : 0] i_funct3   //! funct3 field from instruction
);
    //! ALU Operations
    localparam ALU_ADD    = 5'b00000;
    localparam ALU_SUB    = 5'b00001;
    localparam ALU_SLL    = 5'b00010;
    localparam ALU_SLT    = 5'b00011;
    localparam ALU_SLTU   = 5'b00100;
    localparam ALU_XOR    = 5'b00101;
    localparam ALU_SRL    = 5'b00110;
    localparam ALU_SRA    = 5'b00111;
    localparam ALU_OR     = 5'b01000;
    localparam ALU_AND    = 5'b01001;
    localparam ALU_MUL    = 5'b01010;
    localparam ALU_MULH   = 5'b01011;
    localparam ALU_MULHSU = 5'b01100;
    localparam ALU_MULHU  = 5'b01101;
    localparam ALU_DIV    = 5'b01110;
    localparam ALU_DIVU   = 5'b01111;
    localparam ALU_REM    = 5'b10000;
    localparam ALU_REMU   = 5'b10001;

    //! ALU Control Unit Model
    always @(*) begin
        case (i_alu_op)
            2'b00: begin // Load/Store Instructions
                o_alu_op = ALU_ADD;
            end
            2'b01: begin // Branch Instructions
                case (i_funct3)
                    3'b000: o_alu_op = ALU_SUB;  // BEQ
                    3'b001: o_alu_op = ALU_SUB;  // BNE
                    3'b100: o_alu_op = ALU_SLT;  // BLT
                    3'b101: o_alu_op = ALU_SLT;  // BGE
                    3'b110: o_alu_op = ALU_SLTU; // BLTU
                    3'b111: o_alu_op = ALU_SLTU; // BGEU
                    default: o_alu_op = ALU_ADD;
                endcase
            end
            2'b10: begin // I-Type Arithmetic Instructions
                case (i_funct3)
                    3'b000: o_alu_op = ALU_ADD;  // ADDI
                    3'b001: o_alu_op = ALU_SLL;  // SLLI
                    3'b010: o_alu_op = ALU_SLT;  // SLTI
                    3'b011: o_alu_op = ALU_SLTU; // SLTIU
                    3'b100: o_alu_op = ALU_XOR;  // XORI
                    3'b101: begin
                        case (i_funct7)
                            7'b0000000: o_alu_op = ALU_SRL; // SRLI
                            7'b0100000: o_alu_op = ALU_SRA; // SRAI
                            default: o_alu_op = ALU_ADD;
                        endcase
                    end
                    3'b110: o_alu_op = ALU_OR;   // ORI
                    3'b111: o_alu_op = ALU_AND;  // ANDI
                    
                    default: o_alu_op = ALU_ADD;
                endcase
            end
            2'b11: begin // R-Type Instructions
                case ({i_funct7, i_funct3})
                    10'b0000000000 : o_alu_op = ALU_ADD   ;
                    10'b0100000000 : o_alu_op = ALU_SUB   ;
                    10'b0000000100 : o_alu_op = ALU_XOR   ;
                    10'b0000000110 : o_alu_op = ALU_OR    ;
                    10'b0000000111 : o_alu_op = ALU_AND   ;
                    10'b0000000001 : o_alu_op = ALU_SLL   ;
                    10'b0000000101 : o_alu_op = ALU_SRL   ;
                    10'b0100000101 : o_alu_op = ALU_SRA   ;
                    10'b0000000010 : o_alu_op = ALU_SLT   ;
                    10'b0000000011 : o_alu_op = ALU_SLTU  ;
                    10'b0000001000 : o_alu_op = ALU_MUL   ;
                    10'b0000001001 : o_alu_op = ALU_MULH  ;
                    10'b0000001010 : o_alu_op = ALU_MULHSU;
                    10'b0000001011 : o_alu_op = ALU_MULHU ;
                    10'b0000001100 : o_alu_op = ALU_DIV   ;
                    10'b0000001101 : o_alu_op = ALU_DIVU  ;
                    10'b0000001110 : o_alu_op = ALU_REM   ;
                    10'b0000001111 : o_alu_op = ALU_REMU  ;
                    default        : o_alu_op = ALU_ADD   ;
                endcase
            end
            default: o_alu_op = ALU_ADD;
        endcase
    end

endmodule