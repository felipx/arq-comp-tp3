//! @title MEMORY
//! @file memory.v
//! @author Felipe Montero Bruni
//! @date 07-2024
//! @version 0.1

module memory
#(
    parameter ADDR_WIDTH = 10,                //! Address width
    parameter DATA_WIDTH = 32                 //! Size of each memory location
) (
    output reg  [DATA_WIDTH - 1 : 0] o_dout,  //! Data output
    input  wire [DATA_WIDTH - 1 : 0] i_din ,  //! Data input
    input  wire [ADDR_WIDTH - 1 : 0] i_addr,  //! Address input
    input  wire                      i_wen ,  //! Write enable input
    input  wire                      i_ren ,  //! Read enable input
    input  wire                      i_rst ,  //! Reset
    input  wire                      clk      //! Clock
);

    //! Local Parameters
    localparam DATA_DEPTH = 2**ADDR_WIDTH;

    //! Internal Signals
    reg [DATA_WIDTH - 1 : 0] ram_array [DATA_DEPTH - 1 : 0];

    integer index;

    //! Initial block for memory initialization (sim only)
    initial begin
        for (index = 0; index < RAM_DEPTH; index = index + 1)
            ram_array[index] = {RAM_WIDTH{1'b0}};
    end

    //! Memory operations
    always @(posedge clk) begin
        if (i_rst) begin
            // Reset logic: Clear all memory locations
            for (index = 0; index < DATA_DEPTH; index = index + 1) begin
                ram_array[index] <= {DATA_WIDTH{1'b0}};
            end
            o_dout <= {DATA_WIDTH{1'b0}};
        end
        else begin
            if (i_wen && !i_ren) begin
                // Write operation: only if write enable is high
                ram_array[i_addr] <= i_din;
            end
            else if (i_ren && !i_wen) begin
                // Read operation: only if read enable is high
                o_dout <= ram_array[i_addr];
            end
            else if (i_wen && i_ren) begin
                // If both read and write enables are high, prioritize write and then read
                ram_array[i_addr] <= i_din;
                o_dout <= i_din;
            end
        end
    end
    
endmodule