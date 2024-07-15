module base_integer_ctrl_unit
# (

) (
    // Outputs
    output reg          o_RegWrite,  //! Register Write enable
    output reg          o_MemRead ,  //! Memory Read enable
    output reg          o_MemWrite,  //! Memory Write enable
    output reg          o_ALUSrc  ,  //! ALU Source select
    output reg          o_MemToReg,  //! Memory to Register select
    output reg          o_Branch  ,  //! Branch control
    output reg          o_Jump    ,  //! Jump control
    output reg  [1 : 0] o_ALUOp   ,  //! ALU Operation
    
    // Input
    input  wire [6 : 0] i_opcode     //! Opcode from the instruction
);

    // Opcode definitions
    localparam R_TYPE   = 7'b0110011;
    localparam I_TYPE_1 = 7'b0010011;
    localparam I_TYPE_2 = 7'b0000011;
    localparam I_TYPE_3 = 7'b1100111;
    localparam I_TYPE_4 = 7'b1110011;
    localparam S_TYPE   = 7'b0100011;
    localparam B_TYPE   = 7'b1100011;
    localparam U_TYPE_1 = 7'b0110111;
    localparam U_TYPE_2 = 7'b0010111;
    localparam J_TYPE   = 7'b1101111;

    // Base Integer Control Unit Logic
    always @(*) begin
        case (opcode)
            R_TYPE: begin
                o_RegWrite = 1;
                o_MemRead  = 0;
                o_MemWrite = 0;
                o_ALUSrc   = 0;
                o_MemToReg = 0;
                o_Branch   = 0;
                o_Jump     = 0;
                o_ALUOp    = 2'b10;
            end
            I_TYPE_1, I_TYPE_3, I_TYPE_4: begin
                o_RegWrite = 1;
                o_MemRead  = 0;
                o_MemWrite = 0;
                o_ALUSrc   = 1;
                o_MemToReg = 0;
                o_Branch   = 0;
                o_Jump     = (opcode == I_TYPE_3) ? 1 : 0;
                o_ALUOp    = (opcode == I_TYPE_4) ? 2'b00 : 2'b10;
            end
            I_TYPE_2: begin
                o_RegWrite = 1;
                o_MemRead  = 1;
                o_MemWrite = 0;
                o_ALUSrc   = 1;
                o_MemToReg = 1;
                o_Branch   = 0;
                o_Jump     = 0;
                o_ALUOp    = 2'b00;
            end
            S_TYPE: begin
                o_RegWrite = 0;
                o_MemRead  = 0;
                o_MemWrite = 1;
                o_ALUSrc   = 1;
                o_MemToReg = 0;
                o_Branch   = 0;
                o_Jump     = 0;
                o_ALUOp    = 2'b00;
            end
            B_TYPE: begin
                o_RegWrite = 0;
                o_MemRead  = 0;
                o_MemWrite = 0;
                o_ALUSrc   = 0;
                o_MemToReg = 0;
                o_Branch   = 1;
                o_Jump     = 0;
                o_ALUOp    = 2'b01;
            end
            U_TYPE_1, U_TYPE_2: begin
                o_RegWrite = 1;
                o_MemRead  = 0;
                o_MemWrite = 0;
                o_ALUSrc   = 1;
                o_MemToReg = 0;
                o_Branch   = 0;
                o_Jump     = 0;
                o_ALUOp    = 2'b00;
            end
            J_TYPE: begin
                o_RegWrite = 1;
                o_MemRead  = 0;
                o_MemWrite = 0;
                o_ALUSrc   = 0;
                o_MemToReg = 0;
                o_Branch   = 0;
                o_Jump     = 1;
                o_ALUOp    = 2'b00;
            end
            default: begin
                o_RegWrite = 0;
                o_MemRead  = 0;
                o_MemWrite = 0;
                o_ALUSrc   = 0;
                o_MemToReg = 0;
                o_Branch   = 0;
                o_Jump     = 0;
                o_ALUOp    = 2'b00;
            end
        endcase
    end

endmodule