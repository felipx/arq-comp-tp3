module alu
#(
    parameter NB_DATA = 32,                 //! Data width of the ALU
    parameter NB_CTRL = 5                   //! Control signal width
) (
    // Outputs
    output reg [NB_DATA - 1 : 0] o_result,  //! ALU result
    output                       o_zero  ,  //! Zero flag (if result is zero)
                                          
    // Inputs                             
    input      [NB_DATA - 1 : 0] i_data1 ,  //! First operand
    input      [NB_DATA - 1 : 0] i_data2 ,  //! Second operand
    input      [NB_CTRL - 1 : 0] i_alu_op   //! ALU operation control signal
    
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
    localparam ALU_MUL     = 5'b01010;
    localparam ALU_MULH    = 5'b01011;
    localparam ALU_MULHSU  = 5'b01100;
    localparam ALU_MULHU   = 5'b01101;
    localparam ALU_DIV     = 5'b01110;
    localparam ALU_DIVU    = 5'b01111;
    localparam ALU_REM     = 5'b10000;
    localparam ALU_REMU    = 5'b10001;

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
            ALU_MUL:    o_result = i_data1 * i_data2;
            ALU_MULH:   o_result = ($signed(i_data1) * $signed(i_data2)) >> DATA_WIDTH;
            ALU_MULHSU: o_result = ($signed(i_data1) * i_data2) >> DATA_WIDTH;
            ALU_MULHU:  o_result = (i_data1 * i_data2) >> DATA_WIDTH;
            ALU_DIV:    o_result = $signed(i_data1) / $signed(i_data2);
            ALU_DIVU:   o_result = i_data1 / i_data2;
            ALU_REM:    o_result = $signed(i_data1) % $signed(i_data2);
            ALU_REMU:   o_result = i_data1 % i_data2;
            default:    o_result = 0;
        endcase
    end

    // Zero flag
    assign o_zero = (o_result == 0) ? 1'b1 : 1'b0;

endmodule