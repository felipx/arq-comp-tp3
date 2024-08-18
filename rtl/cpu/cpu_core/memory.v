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
    output reg [31 : 0] o_dout,               //! Data output
    
    // Inputs
    input  wire [31 : 0]             i_din  ,  //! Data input
    input  wire [ADDR_WIDTH - 1 : 0] i_waddr,  //! Write address input
    input  wire [ADDR_WIDTH - 1 : 0] i_raddr,  //! Read address input
    input  wire [1 : 0]              i_size ,  //! Write/Read size (byte, half, word) input
    input  wire                      i_wen  ,  //! Write enable input
    input  wire                      i_ren  ,  //! Read enable input
    input  wire                      clk       //! Clock
);

    localparam RAM_ADDR_WIDTH = ADDR_WIDTH - 2;

    reg [3 : 0]                  ram_wen     ;
    reg [RAM_ADDR_WIDTH - 1 : 0] waddr [3:0] ;
    reg [RAM_ADDR_WIDTH - 1 : 0] raddr [3:0] ;
    reg [31 : 0]                 din_shifted ;
    reg [31 : 0]                 dout_shifted;
    
    wire [7 : 0] ram_dout [3:0];
    wire [1 : 0] write_shift   ;
    wire [1 : 0] read_shift    ;
    
    wire [ADDR_WIDTH-2:0] base_waddr = i_waddr >> 2;
    wire [ADDR_WIDTH-2:0] base_raddr = i_raddr >> 2;

    // Shift Logic
    assign write_shift = i_waddr[1:0];
    assign read_shift  = i_raddr[1:0];


    // RAM Banks
    generate
        for (genvar i = 0; i < 4; i = i + 1) begin : ram_bank_gen
            bram 
            #(
                .ADDR_WIDTH (RAM_ADDR_WIDTH)
            )
                u_ram_bank
                (
                    .o_dout  (ram_dout[i]                   ),
                    .i_we    (ram_wen[i]                    ),
                    .i_re    (i_ren                         ),
                    .i_waddr (waddr[i]                      ),
                    .i_raddr (raddr[i]                      ),
                    .i_di    (din_shifted[(8*(i+1)-1) : 8*i]),
                    .clk     (clk                           )
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
                4'b0101: ram_wen = 4'b0000;
                4'b1001: ram_wen = 4'b0000;
                4'b1101: ram_wen = 4'b0000;
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

        waddr[0] = base_waddr + (write_shift >= 2'd1);
        waddr[1] = base_waddr + (write_shift >= 2'd2);
        waddr[2] = base_waddr + (write_shift >= 2'd3);
        waddr[3] = base_waddr;

        din_shifted = ({i_din, i_din} >> (write_shift * 8));
    end

    // Read Logic
    always @(*) begin
        o_dout = {32{1'b0}};
        raddr[0] = base_raddr + (read_shift >= 2'd1);
        raddr[1] = base_raddr + (read_shift >= 2'd2);
        raddr[2] = base_raddr + (read_shift >= 2'd3);
        raddr[3] = base_raddr;

        dout_shifted = ({ram_dout[3], ram_dout[2], ram_dout[1], ram_dout[0], ram_dout[3], ram_dout[2], ram_dout[1], ram_dout[0]} >> (read_shift * 8));

        if (i_ren) begin 
            o_dout = dout_shifted;
        end
    end

endmodule