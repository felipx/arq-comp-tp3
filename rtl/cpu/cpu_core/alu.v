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
    output                       o_zero  ,  //! Zero flag (if result is zero)

                                          
    // Inputs                             
    input      [NB_DATA - 1 : 0] i_data1 ,  //! First operand
    input      [NB_DATA - 1 : 0] i_data2 ,  //! Second operand
    input      [4           : 0] i_alu_op   //! ALU operation control signal
    
);
    // ALU Operation Encoding
    localparam ALU_ADD     = 5'b00000;
    localparam ALU_SUB     = 5'b00001;
    localparam ALU_SLL     = 5'b00010;
    localparam ALU_SLT     = 5'b00011;
    localparam ALU_SLTU    = 5'b00100;
    localparam ALU_XOR     = 5'b00101;
    localparam ALU_SRL     = 5'b00110;
    localparam ALU_SRA     = 5'b00111;
    localparam ALU_OR      = 5'b01000;
    localparam ALU_AND     = 5'b01001;


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

    // Result = 0 signal
    assign o_zero           = (o_result == 0) ? 1'b1 : 1'b0        ;

endmodule