module decoder_2to4
(
    // Output
    output reg [3 : 0] o_out,

    // Input
    input wire [1 : 0] i_sel,
    input wire         i_en 
);

    always @(*) begin
        o_out = 4'b0000;
        if (i_en) begin
            case (i_sel)
                2'b00  : o_out = 4'b0001;
                2'b01  : o_out = 4'b0010;
                2'b10  : o_out = 4'b0100;
                2'b11  : o_out = 4'b1000;
            endcase
        end
    end
    
endmodule