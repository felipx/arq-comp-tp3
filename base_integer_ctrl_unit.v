//! @title BASE INTEGER CONTROL UNIT
//! @file base_integer_ctrl_unit.v
//! @author Felipe Montero Bruni
//! @date 07-2024
//! @version 0.1

module base_integer_ctrl_unit
# (
    parameter NB_CTRL   = 9;
    parameter NB_OPCODE = 7;
) (
    // Outputs
    output reg [NB_CTRL    - 1 : 0] o_ctrl,   //! Control signals output
    
    // Input
    input  wire [NB_OPCODE - 1 : 0] i_opcode  //! Opcode from the instruction
);

    ///////////////////////////////////////////////////////////////
    // Ouput Model                                               //
    // o_ctrl[0]   == o_RegWrite,  //! Register Write enable     //
    // o_ctrl[1]   == o_MemRead ,  //! Memory Read enable        //
    // o_ctrl[2]   == o_MemWrite,  //! Memory Write enable       //
    // o_ctrl[3]   == o_ALUSrc  ,  //! ALU Source select         //
    // o_ctrl[4]   == o_MemToReg,  //! Memory to Register select //
    // o_ctrl[5]   == o_Branch  ,  //! Branch control            //
    // o_ctrl[6]   == o_Jump    ,  //! Jump control              //
    // o_ctrl[8:7] == o_ALUOp   ,  //! ALU Operation             //
    ///////////////////////////////////////////////////////////////

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
                o_ctrl[0]   = 1;
                o_ctrl[1]   = 0;
                o_ctrl[2]   = 0;
                o_ctrl[3]   = 0;
                o_ctrl[4]   = 0;
                o_ctrl[5]   = 0;
                o_ctrl[6]   = 0;
                o_ctrl[8:7] = 2'b10;
            end
            I_TYPE_1, I_TYPE_3, I_TYPE_4: begin
                o_ctrl[0]   = 1;
                o_ctrl[1]   = 0;
                o_ctrl[2]   = 0;
                o_ctrl[3]   = 1;
                o_ctrl[4]   = 0;
                o_ctrl[5]   = 0;
                o_ctrl[6]   = (opcode == I_TYPE_3) ? 1 : 0;
                o_ctrl[8:7] = (opcode == I_TYPE_4) ? 2'b00 : 2'b10;
            end
            I_TYPE_2: begin
                o_ctrl[0]   = 1;
                o_ctrl[1]   = 1;
                o_ctrl[2]   = 0;
                o_ctrl[3]   = 1;
                o_ctrl[4]   = 1;
                o_ctrl[5]   = 0;
                o_ctrl[6]   = 0;
                o_ctrl[8:7] = 2'b00;
            end
            S_TYPE: begin
                o_ctrl[0]   = 0;
                o_ctrl[1]   = 0;
                o_ctrl[2]   = 1;
                o_ctrl[3]   = 1;
                o_ctrl[4]   = 0;
                o_ctrl[5]   = 0;
                o_ctrl[6]   = 0;
                o_ctrl[8:7] = 2'b00;
            end
            B_TYPE: begin
                o_ctrl[0]   = 0;
                o_ctrl[1]   = 0;
                o_ctrl[2]   = 0;
                o_ctrl[3]   = 0;
                o_ctrl[4]   = 0;
                o_ctrl[5]   = 1;
                o_ctrl[6]   = 0;
                o_ctrl[8:7] = 2'b01;
            end
            U_TYPE_1, U_TYPE_2: begin
                o_ctrl[0]   = 1;
                o_ctrl[1]   = 0;
                o_ctrl[2]   = 0;
                o_ctrl[3]   = 1;
                o_ctrl[4]   = 0;
                o_ctrl[5]   = 0;
                o_ctrl[6]   = 0;
                o_ctrl[8:7] = 2'b00;
            end
            J_TYPE: begin
                o_ctrl[0]   = 1;
                o_ctrl[1]   = 0;
                o_ctrl[2]   = 0;
                o_ctrl[3]   = 0;
                o_ctrl[4]   = 0;
                o_ctrl[5]   = 0;
                o_ctrl[6]   = 1;
                o_ctrl[8:7] = 2'b00;
            end
            default: begin
                o_ctrl = {NB_CTRL{1'b0}};
            end
        endcase
    end

endmodule