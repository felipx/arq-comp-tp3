//! @title BASE INTEGER CONTROL UNIT
//! @file base_integer_ctrl_unit.v
//! @author Felipe Montero Bruni
//! @date 07-2024
//! @version 0.1

module base_integer_ctrl_unit
# (
    parameter NB_CTRL = 9
) (
    // Outputs
    output reg  [NB_CTRL - 1 : 0] o_ctrl,  //! Control signals output
    
    // Input
    input  wire [6 : 0] i_opcode,          //! Instruction's opcode field
    input  wire [2 : 0] i_func3            //! Instruction's func3 field
);

    ///////////////////////////////////////////////////////////////
    // Ouput Model                                               //
    // o_ctrl[0]   == o_regWrite,  //! Register Write enable     //
    // o_ctrl[1]   == o_memRead ,  //! Memory Read enable        //
    // o_ctrl[2]   == o_memWrite,  //! Memory Write enable       //
    // o_ctrl[3]   == o_ALUSrc  ,  //! ALU Source select         //
    // o_ctrl[4]   == o_memToReg,  //! Memory to Register select // 
    // o_ctrl[6:5] == o_ALUOp   ,  //! ALU Operation             //
    // o_ctrl[8:7] == o_dataSize,  //! Reg store/load size       //
    ///////////////////////////////////////////////////////////////

    // Opcode definitions
    localparam R_TYPE   = 7'b0110011;
    localparam I_TYPE_1 = 7'b0010011;
    localparam I_TYPE_2 = 7'b0000011;
    localparam S_TYPE   = 7'b0100011;
    localparam U_TYPE_1 = 7'b0110111;
    localparam U_TYPE_2 = 7'b0010111;

    // Base Integer Control Unit Logic
    always @(*) begin
        o_ctrl = {NB_CTRL{1'b0}};

        case (i_func3)
            3'b000 : o_ctrl[8:7] = 2'b01; // LB
            3'b001 : o_ctrl[8:7] = 2'b10; // LH
            3'b010 : o_ctrl[8:7] = 2'b11; // LW
            3'b100 : o_ctrl[8:7] = 2'b01; // LB (U)
            3'b101 : o_ctrl[8:7] = 2'b10; // LH (U)
            default: o_ctrl[8:7] = 2'b00; // Error condition 
        endcase

        case (i_opcode)
            R_TYPE: begin              // Arithmetic R Instructions
                o_ctrl[0]   = 1'b1;
                o_ctrl[6:5] = 2'b11;
            end
            I_TYPE_1: begin           // Arithmetic I
                o_ctrl[0]   = 1'b1;
                o_ctrl[3]   = 1'b1;
                o_ctrl[6:5] = 2'b10;
            end
            I_TYPE_2: begin            // Load Instructions
                o_ctrl[0]   = 1'b1;
                o_ctrl[1]   = 1'b1;
                o_ctrl[3]   = 1'b1;
                o_ctrl[4]   = 1'b1;
            end
            S_TYPE: begin              // Store Instructions
                o_ctrl[2]   = 1'b1;
                o_ctrl[3]   = 1'b1;
            end
            U_TYPE_1, U_TYPE_2: begin  // LUI and AUIPC
                o_ctrl[0]    = 1'b1;
                o_ctrl[3]    = 1'b1;
            end
            default: begin
                o_ctrl = {NB_CTRL{1'b0}};
            end
        endcase
    end

endmodule