//! @title BlOCK RAM
//! @file bram.v
//! @author Felipe Montero Bruni
//! @date 07-2024
//! @version 0.1

module bram
#(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8                 //! Address width
) (
    // Output
    output reg [DATA_WIDTH - 1 : 0] o_dout1,
    output reg [DATA_WIDTH - 1 : 0] o_dout2,

    // Inputs
    input                       i_we    ,
    input                       i_re1   ,
    input                       i_re2   ,
    input [ADDR_WIDTH - 1 : 0]  i_waddr ,
    input [ADDR_WIDTH - 1 : 0]  i_raddr1,
    input [ADDR_WIDTH - 1 : 0]  i_raddr2,
    input [DATA_WIDTH - 1 : 0]  i_di    ,
    input                       clk    
);
    
    //! Local Parameters
    localparam DATA_DEPTH = 2**ADDR_WIDTH;
    
    (* ram_style = "block" *) reg [DATA_WIDTH - 1 : 0] ram [DATA_DEPTH - 1 : 0];
    
    //! Initial block for memory initialization (simulation only)
    integer i;
    initial begin
        for (i = 0; i < DATA_DEPTH; i = i + 1)
            ram[i] = {DATA_WIDTH{1'b0}};
    end
    
    //! Write Logic
    always @(posedge clk) begin
        if (i_we)
            ram[i_waddr] <= i_di;
    end
    
    //! Read Logic 1
    always @(negedge clk) begin
        if (i_re1)
            o_dout1 <= ram[i_raddr1];
    end

    //! Read Logic 2
    always @(negedge clk) begin
        if (i_re2)
            o_dout2 <= ram[i_raddr2];
    end

endmodule