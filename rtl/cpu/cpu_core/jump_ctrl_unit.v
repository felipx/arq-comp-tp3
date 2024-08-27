module jump_ctrl_unit
#(
    parameter NB_PC = 32
) (
    // Ouputs
    output reg [1 : 0] o_pcSrc   ,
    output reg         o_regWrite,
    output reg         o_flush   ,

    // Inputs
    input wire [6 : 0] i_opcode  ,
    input wire         i_stall    
);
    
    localparam J_TYPE   = 7'b1101111;  // JAL
    localparam I_TYPE_3 = 7'b1100111;  // JARL

    always @(*) begin
        o_pcSrc    = 2'b00;
        o_regWrite = 1'b0;
        o_flush    = 1'b0;
        
        if (~i_stall) begin
            case (i_opcode)
                J_TYPE: begin 
                    o_pcSrc    = 2'b01;
                    o_regWrite = 1'b1;
                    o_flush    = 1'b1;
                end
                I_TYPE_3: begin 
                    o_pcSrc    = 2'b10;
                    o_regWrite = 1'b1;
                    o_flush    = 1'b1;
                end
                default: begin
                    o_pcSrc    = 2'b00;
                    o_regWrite = 1'b0;
                    o_flush    = 1'b0;
                end
            endcase
        end
    end
    
endmodule