//! @title MEMORY
//! @file memory.v
//! @author Felipe Montero Bruni
//! @date 07-2024
//! @version 0.1

module memory
#(
    parameter ADDR_WIDTH = 5                 //! Address width
) (
    // Output
    output reg  [31             : 0] o_dout,   //! Data output
    
    // Inputs
    input  wire [31             : 0] i_din  ,  //! Data input
    input  wire [ADDR_WIDTH - 1 : 0] i_waddr,  //! Write address input
    input  wire [ADDR_WIDTH - 1 : 0] i_raddr,  //! Read address input
    input  wire [1              : 0] i_wsize,  //! Write size (byte, half, word) input
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
    (* ram_style = "block" *) reg [NB_BYTE - 1 : 0] ram [DATA_DEPTH - 1 : 0];

    integer index;

    //! Initial block for memory initialization (sim only)
    initial begin
        for (index = 0; index < DATA_DEPTH; index = index + 1)
            ram[index] = {NB_BYTE{1'b0}};
    end

    //! SB Write Logic
    always @(posedge clk) begin
        if (i_wen) begin
            case (i_wsize)
                2'b01, 2'b10, 2'b11: ram[i_waddr] <= i_din[7 :  0];
                default: ram[i_waddr] <= ram[i_waddr];
            endcase
        end
    end

    //! SH Write Logic
    always @(posedge clk) begin
        if (i_wen) begin
            case (i_wsize)
                2'b10, 2'b11: ram[i_waddr + 1] <= i_din[15 :  8];
                default: ram[i_waddr + 1] <= ram[i_waddr + 1];
            endcase
        end
    end

    //! SW Write Logic
    always @(posedge clk) begin
        if (i_wen) begin
            case (i_wsize)
                2'b11: ram[i_waddr + 2] <= i_din[23 :  16];
                default: ram[i_waddr + 2] <= ram[i_waddr + 2]; 
            endcase
        end
    end

    //! SW Write Logic
    always @(posedge clk) begin
        if (i_wen) begin
            case (i_wsize)
                2'b11: ram[i_waddr + 3] <= i_din[31 :  24];
                default: ram[i_waddr + 3] <= ram[i_waddr + 3]; 
            endcase
        end
    end

    //! Read Logic
    always @(posedge clk) begin
        if (i_rst) begin
            o_dout <= {NB_WORD{1'b0}};
        end
        else if (i_ren) begin
            o_dout <= {ram[i_raddr+3], ram[i_raddr+2], ram[i_raddr+1], ram[i_raddr]};
        end
    end
    
endmodule