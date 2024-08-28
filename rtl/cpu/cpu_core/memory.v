//! @title MEMORY
//! @file memory.v
//! @author Felipe Montero Bruni
//! @date 07-2024
//! @version 0.1

module memory
#(
    parameter ADDR_WIDTH = 10  //! Address width
) (
    // Output
    output reg [31 : 0] o_dout1,               //! Data output
    output reg [31 : 0] o_dout2,               //! Data output
    
    // Inputs
    input  wire [31 : 0]             i_din  ,  //! Data input
    input  wire [ADDR_WIDTH - 1 : 0] i_waddr,  //! Write address input
    input  wire [ADDR_WIDTH - 1 : 0] i_raddr1,  //! Read address input
    input  wire [ADDR_WIDTH - 1 : 0] i_raddr2,  //! Read address input
    input  wire [1 : 0]              i_size ,  //! Write/Read size (byte, half, word) input
    input  wire                      i_wen  ,  //! Write enable input
    input  wire                      i_ren1  ,  //! Read enable input
    input  wire                      i_ren2  ,  //! Read enable input
    input  wire                      clk       //! Clock
);

    localparam DATA_WIDTH     = 8             ;
    localparam RAM_ADDR_WIDTH = ADDR_WIDTH - 2;

    reg [3 : 0]                  ram_wen             ;
    reg [RAM_ADDR_WIDTH - 1 : 0] waddr         [3:0] ;
    reg [RAM_ADDR_WIDTH - 1 : 0] raddr1        [3:0] ;
    reg [RAM_ADDR_WIDTH - 1 : 0] raddr2        [3:0] ;
    reg [31 : 0]                 din_shifted         ;
    reg [31 : 0]                 dout_shifted1       ;
    reg [31 : 0]                 dout_shifted2       ;
    
    wire [7 : 0] ram_dout1 [3:0];
    wire [7 : 0] ram_dout2 [3:0];
    
    // RAM Banks
    generate
        for (genvar i = 0; i < 4; i = i + 1) begin : ram_bank_gen
            bram 
            #(
                .DATA_WIDTH (DATA_WIDTH    ),
                .ADDR_WIDTH (RAM_ADDR_WIDTH)
            )
                u_ram_bank
                (
                    .o_dout1  (ram_dout1[i]                  ),
                    .o_dout2  (ram_dout2[i]                  ),
                    .i_we     (ram_wen[i]                    ),
                    .i_re1    (i_ren1                        ),
                    .i_re2    (i_ren2                        ),
                    .i_waddr  (waddr[i]                      ),
                    .i_raddr1 (raddr1[i]                     ),
                    .i_raddr2 (raddr2[i]                     ),
                    .i_di     (din_shifted[(8*(i+1)-1) : 8*i]),
                    .clk      (clk                           )
                );
        end
    endgenerate

    // Write Logic
    always @(*) begin
        ram_wen = 4'h0;

        if (i_wen) begin
            case ({i_waddr[1:0], i_size})
                // SB
                4'b0001: ram_wen = 4'b0001;
                4'b0101: ram_wen = 4'b0010;
                4'b1001: ram_wen = 4'b0100;
                4'b1101: ram_wen = 4'b1000;
                // SH
                4'b0010: ram_wen = 4'b0011;
                4'b0110: ram_wen = 4'b0110;
                4'b1010: ram_wen = 4'b1100;
                4'b1110: ram_wen = 4'b1001;
                // SW
                4'b0011: ram_wen =  4'b1111;
                4'b0111: ram_wen =  4'b1111;
                4'b1011: ram_wen =  4'b1111;
                4'b1111: ram_wen =  4'b1111;
        
                default: ram_wen = 4'b0000;
            endcase
        end

        waddr[0] = (i_waddr >> 2) + (i_waddr[1:0] >= 2'd1);
        waddr[1] = (i_waddr >> 2) + (i_waddr[1:0] >= 2'd2);
        waddr[2] = (i_waddr >> 2) + (i_waddr[1:0] >= 2'd3);
        waddr[3] = (i_waddr >> 2)                         ;

        din_shifted = ({i_din, i_din} >> (i_waddr[1:0] * 8));
    end

    // Read Logic1
    always @(*) begin
        o_dout1 = {32{1'b0}};
        raddr1[0] = (i_raddr1 >> 2) + (i_raddr1[1:0] >= 2'd1);
        raddr1[1] = (i_raddr1 >> 2) + (i_raddr1[1:0] >= 2'd2);
        raddr1[2] = (i_raddr1 >> 2) + (i_raddr1[1:0] >= 2'd3);
        raddr1[3] = (i_raddr1 >> 2)                          ;

        dout_shifted1 = ({ram_dout1[3], ram_dout1[2], ram_dout1[1], ram_dout1[0], ram_dout1[3], ram_dout1[2], ram_dout1[1], ram_dout1[0]} >> (i_raddr1[1:0] * 8));

        if (i_ren1) begin 
            o_dout1 = dout_shifted1;
        end
    end

    // Read Logic2
    always @(*) begin
        o_dout2 = {32{1'b0}};
        raddr2[0] = (i_raddr2 >> 2) + (i_raddr2[1:0] >= 2'd1);
        raddr2[1] = (i_raddr2 >> 2) + (i_raddr2[1:0] >= 2'd2);
        raddr2[2] = (i_raddr2 >> 2) + (i_raddr2[1:0] >= 2'd3);
        raddr2[3] = (i_raddr2 >> 2)                          ;

        dout_shifted2 = ({ram_dout2[3], ram_dout2[2], ram_dout2[1], ram_dout2[0], ram_dout2[3], ram_dout2[2], ram_dout2[1], ram_dout2[0]} >> (i_raddr2[1:0] * 8));

        if (i_ren2) begin 
            o_dout2 = dout_shifted2;
        end
    end

endmodule