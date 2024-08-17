//! @title ALU
//! @file alu.v
//! @author Felipe Montero Bruni
//! @date 07-2024
//! @version 0.1

module alu
#(
    parameter NB_DATA = 32                  //! Data width of the ALU
) (
    // Outputs
    output reg [NB_DATA - 1 : 0] o_result,  //! ALU result
                                 
    // Inputs                             
    input      [NB_DATA - 1 : 0] i_data1 ,  //! First operand
    input      [NB_DATA - 1 : 0] i_data2 ,  //! Second operand
    input      [3           : 0] i_alu_op   //! ALU operation control signal
    
);
    // ALU Operation Encoding
    localparam ALU_ADD     = 4'b0000;
    localparam ALU_SUB     = 4'b0001;
    localparam ALU_SLL     = 4'b0010;
    localparam ALU_SLT     = 4'b0011;
    localparam ALU_SLTU    = 4'b0100;
    localparam ALU_XOR     = 4'b0101;
    localparam ALU_SRL     = 4'b0110;
    localparam ALU_SRA     = 4'b0111;
    localparam ALU_OR      = 4'b1000;
    localparam ALU_AND     = 4'b1001;


    // ALU Logic
    always @(*) begin
        case (i_alu_op)
            ALU_ADD:    o_result = i_data1 + i_data2;
            ALU_SUB:    o_result = i_data1 - i_data2;
            ALU_SLL:    o_result = i_data1 << i_data2[4:0];
            ALU_SLT:    o_result = ($signed(i_data1) < $signed(i_data2)) ? 1 : 0;
            ALU_SLTU:   o_result = (i_data1 < i_data2) ? 1 : 0;
            ALU_XOR:    o_result = i_data1 ^ i_data2;
            ALU_SRL:    o_result = i_data1 >> i_data2[4:0];
            ALU_SRA:    o_result = $signed(i_data1) >>> i_data2[4:0];
            ALU_OR:     o_result = i_data1 | i_data2;
            ALU_AND:    o_result = i_data1 & i_data2;
            default:    o_result = 0;
        endcase
    end

endmodule