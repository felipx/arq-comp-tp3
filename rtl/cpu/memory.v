//! @title MEMORY
//! @file memory.v
//! @author Felipe Montero Bruni
//! @date 07-2024
//! @version 0.1

module memory
#(
    parameter ADDR_WIDTH = 10,                //! Address width
) (
    // Output
    output reg  [31             : 0] o_dout,  //! Data output
    
    // Inputs
    input  wire [31             : 0] i_din  ,  //! Data input
    input  wire [ADDR_WIDTH - 1 : 0] i_addr ,  //! Address input
    input  wire [1              : 0] i_wsize,
    input  wire                      i_wen  ,  //! Write enable input
    input  wire                      i_ren  ,  //! Read enable input
    input  wire                      i_rst  ,  //! Reset
    input  wire                      clk       //! Clock
);

    //! Local Parameters
    localparam DATA_DEPTH = 2**ADDR_WIDTH;
    localparam NB_BYTE    = 8            ;
    localparam NB_WORD    = 32           ;

    //! Internal Signals
    reg [NB_BYTE - 1 : 0] ram_array [DATA_DEPTH - 1 : 0];

    integer index;

    //! Initial block for memory initialization (sim only)
    initial begin
        for (index = 0; index < DATA_DEPTH; index = index + 1)
            ram_array[index] = {NB_BYTE{1'b0}};
    end

    //! Memory operations
    always @(posedge clk) begin
        if (i_rst) begin
            // Reset logic: Clear all memory locations
            for (index = 0; index < DATA_DEPTH; index = index + 1) begin
                ram_array[index] <= {NB_BYTE{1'b0}};
            end
            o_dout <= {NB_WORD{1'b0}};
        end
        else begin
            if (i_wen && !i_ren) begin
                // Write operation: only if write enable is high
                case (i_wsize)
                    // SB
                    2'b01: begin
                        ram_array[i_addr] <= i_din[7 : 0];
                    end
                    // SH
                    2'b10: begin
                        ram_array[i_addr    ] <= i_din[7  : 0];
                        ram_array[i_addr + 1] <= i_din[15 : 8];
                    end
                    // SW
                    2'b11: begin
                        ram_array[i_addr    ] <= i_din[7  :  0];
                        ram_array[i_addr + 1] <= i_din[15 :  8];
                        ram_array[i_addr + 2] <= i_din[23 : 16];
                        ram_array[i_addr + 3] <= i_din[31 : 17];
                    end
                    default: begin
                        ram_array[i_addr    ] <= ram_array[i_addr    ];
                        ram_array[i_addr + 1] <= ram_array[i_addr + 1];
                        ram_array[i_addr + 2] <= ram_array[i_addr + 2];
                        ram_array[i_addr + 3] <= ram_array[i_addr + 3];
                    end
                endcase
                ram_array[i_addr] <= i_din;
            end
            else if (i_ren && !i_wen) begin
                // Read operation: only if read enable is high
                o_dout <= {ram_array[i_addr+3], ram_array[i_addr+2], ram_array[i_addr+1], ram_array[i_addr]};
            end
        end
    end
    
endmodule