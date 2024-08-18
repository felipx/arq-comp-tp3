//! @title BlOCK RAM
//! @file bram.v
//! @author Felipe Montero Bruni
//! @date 07-2024
//! @version 0.1

module bram
#(
    parameter ADDR_WIDTH = 8                 //! Address width
) (
    // Output
    output reg [7 : 0]          o_dout,

    // Inputs
    input                       i_we   ,
    input                       i_re   ,
    input [ADDR_WIDTH - 1 : 0]  i_waddr,
    input [ADDR_WIDTH - 1 : 0]  i_raddr,
    input [7 : 0]               i_di   ,
    input                       clk    
);
    
    //! Local Parameters
    localparam DATA_DEPTH = 2**ADDR_WIDTH;
    
    (* ram_style = "block" *) reg [7 : 0] ram [DATA_DEPTH - 1 : 0];
    
    //! Initial block for memory initialization (simulation only)
    integer i;
    initial begin
        for (i = 0; i < DATA_DEPTH; i = i + 1)
            ram[i] = {8{1'b0}};
    end
    
    //! Write Logic
    always @(posedge clk) begin
        if (i_we)
            ram[i_waddr] <= i_di;
    end
    
    //! Read Logic
    always @(negedge clk) begin
        if (i_re)
            o_dout <= ram[i_raddr];
    end

endmodule