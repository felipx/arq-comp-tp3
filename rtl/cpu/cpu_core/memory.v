//! @title MEMORY
//! @file memory.v
//! @author Felipe Montero Bruni
//! @date 07-2024
//! @version 0.1

module memory
#(
    parameter ADDR_WIDTH = 5  //! Address width
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
    input  wire                      i_rst  ,  //! Reset
    input  wire                      clk       //! Clock
);

    localparam RAM_ADDR_WIDTH = ADDR_WIDTH - 2;

    reg [7 : 0] ram_wen_sel;
    reg [7 : 0] ram_din_sel;
    reg [3 : 0] decoder_en;

    reg [RAM_ADDR_WIDTH - 1 : 0] waddr_0;
    reg [RAM_ADDR_WIDTH - 1 : 0] waddr_1;
    reg [RAM_ADDR_WIDTH - 1 : 0] waddr_2;
    reg [RAM_ADDR_WIDTH - 1 : 0] waddr_3;

    reg [RAM_ADDR_WIDTH - 1 : 0] raddr_0;
    reg [RAM_ADDR_WIDTH - 1 : 0] raddr_1;
    reg [RAM_ADDR_WIDTH - 1 : 0] raddr_2;
    reg [RAM_ADDR_WIDTH - 1 : 0] raddr_3;

    wire [3 : 0] decoder_0_wen_out;
    wire [3 : 0] decoder_1_wen_out;
    wire [3 : 0] decoder_2_wen_out;
    wire [3 : 0] decoder_3_wen_out;

    wire ram_0_wen;
    wire ram_1_wen;
    wire ram_2_wen;
    wire ram_3_wen;

    wire [7:0] mux_0_dout;
    wire [7:0] mux_1_dout;
    wire [7:0] mux_2_dout;
    wire [7:0] mux_3_dout;

    wire [7:0] ram_0_dout;
    wire [7:0] ram_1_dout;
    wire [7:0] ram_2_dout;
    wire [7:0] ram_3_dout;

    // Bank select decoder 0
    decoder_2to4
        u_ram_bank_decoder_0
        (
            .o_out (decoder_0_wen_out),
            .i_sel (ram_wen_sel[1:0] ),
            .i_en  (decoder_en[0]    )
        );

    // Bank select decoder 1
    decoder_2to4
        u_ram_bank_decoder_1
        (
            .o_out (decoder_1_wen_out),
            .i_sel (ram_wen_sel[3:2] ),
            .i_en  (decoder_en[1]    )
        );
    
    // Bank select decoder 2
    decoder_2to4
        u_ram_bank_decoder_2
        (
            .o_out (decoder_2_wen_out),
            .i_sel (ram_wen_sel[5:4] ),
            .i_en  (decoder_en[2]    )
        );

    // Bank select decoder 3
    decoder_2to4
        u_ram_bank_decoder_3
        (
            .o_out (decoder_3_wen_out),
            .i_sel (ram_wen_sel[7:6] ),
            .i_en  (decoder_en[3]    )
        );
    
    // RAM 0 Data Mux
    mux_4to1
    #(
        .DATA_WIDTH (8)
    )
        u_ram_0_data_mux
        (
            .o_data  (mux_0_dout),
            .i_data0 (i_din[7  :  0]),
            .i_data1 (i_din[15 :  8]),
            .i_data2 (i_din[23 : 16]),
            .i_data3 (i_din[31 : 24]),
            .i_sel   (ram_din_sel[1:0])
        );
    
    // RAM 2 Data Mux
    mux_4to1
    #(
        .DATA_WIDTH (8)
    )
        u_ram_1_data_mux
        (
            .o_data  (mux_1_dout),
            .i_data0 (i_din[7  :  0]),
            .i_data1 (i_din[15 :  8]),
            .i_data2 (i_din[23 : 16]),
            .i_data3 (i_din[31 : 24]),
            .i_sel   (ram_din_sel[3:2])
        );
    
    // RAM 2 Data Mux
    mux_4to1
    #(
        .DATA_WIDTH (8)
    )
        u_ram_2_data_mux
        (
            .o_data  (mux_2_dout),
            .i_data0 (i_din[7  :  0]),
            .i_data1 (i_din[15 :  8]),
            .i_data2 (i_din[23 : 16]),
            .i_data3 (i_din[31 : 24]),
            .i_sel   (ram_din_sel[5:4])
        );
    
    // RAM 3 Data Mux
    mux_4to1
    #(
        .DATA_WIDTH (8)
    )
        u_ram_3_data_mux
        (
            .o_data  (mux_3_dout),
            .i_data0 (i_din[7  :  0]),
            .i_data1 (i_din[15 :  8]),
            .i_data2 (i_din[23 : 16]),
            .i_data3 (i_din[31 : 24]),
            .i_sel   (ram_din_sel[7:6])
        );

    // Bank 0
    bram
    #(
        .ADDR_WIDTH (RAM_ADDR_WIDTH)
    )
        u_ram_bank_0
        (
            .o_dout  (ram_0_dout),
            .i_we    (ram_0_wen ),
            .i_re    (i_ren     ),
            .i_waddr (waddr_0   ),
            .i_raddr (raddr_0   ),
            .i_di    (mux_0_dout),
            .i_rst   (i_rst     ),
            .clk     (clk       )
        );
    
    // Bank 1
    bram
    #(
        .ADDR_WIDTH (RAM_ADDR_WIDTH)
    )
        u_ram_bank_1
        (
            .o_dout  (ram_1_dout),
            .i_we    (ram_1_wen ),
            .i_re    (i_ren     ),
            .i_waddr (waddr_1   ),
            .i_raddr (raddr_1   ),
            .i_di    (mux_1_dout),
            .i_rst   (i_rst     ),
            .clk     (clk       )
        );
    
    // Bank 2
    bram
    #(
        .ADDR_WIDTH (RAM_ADDR_WIDTH)
    )
        u_ram_bank_2
        (
            .o_dout  (ram_2_dout),
            .i_we    (ram_2_wen ),
            .i_re    (i_ren     ),
            .i_waddr (waddr_2   ),
            .i_raddr (raddr_2   ),
            .i_di    (mux_2_dout),
            .i_rst   (i_rst     ),
            .clk     (clk       )
        );
    
    // Bank 3
    bram
    #(
        .ADDR_WIDTH (RAM_ADDR_WIDTH)
    )
        u_ram_bank_3
        (
            .o_dout  (ram_3_dout),
            .i_we    (ram_3_wen ),
            .i_re    (i_ren     ),
            .i_waddr (waddr_3   ),
            .i_raddr (raddr_3   ),
            .i_di    (mux_3_dout),
            .i_rst   (i_rst     ),
            .clk     (clk       )
        );

    assign ram_0_wen   = decoder_0_wen_out[0] | decoder_1_wen_out[0] | decoder_2_wen_out[0] | decoder_3_wen_out[0]; 
    assign ram_1_wen   = decoder_0_wen_out[1] | decoder_1_wen_out[1] | decoder_2_wen_out[1] | decoder_3_wen_out[1]; 
    assign ram_2_wen   = decoder_0_wen_out[2] | decoder_1_wen_out[2] | decoder_2_wen_out[2] | decoder_3_wen_out[2]; 
    assign ram_3_wen   = decoder_0_wen_out[3] | decoder_1_wen_out[3] | decoder_2_wen_out[3] | decoder_3_wen_out[3];

    function [1 : 0] trunc_3to2(input [2 : 0] val);
        trunc_3to2 = val[1 : 0];
    endfunction

    // Write Logic
    always @(*) begin
        ram_wen_sel = 8'h00;
        ram_din_sel = 8'h00;
        decoder_en  = 4'h0;
        waddr_0     = {RAM_ADDR_WIDTH{1'b0}};
        waddr_1     = {RAM_ADDR_WIDTH{1'b0}};
        waddr_2     = {RAM_ADDR_WIDTH{1'b0}};
        waddr_3     = {RAM_ADDR_WIDTH{1'b0}};

        if (i_wen) begin
            case (i_size)
                // SB
                2'b01: begin
                    ram_wen_sel[1:0] = i_waddr[1:0];
                    decoder_en[0]    = 1'b1;
                end
                // SH
                2'b10: begin
                    ram_wen_sel[1:0] = i_waddr[1:0];
                    ram_wen_sel[3:2] = trunc_3to2(i_waddr[1:0] + 1'b1);
                    decoder_en[1:0]  = 2'b11;
                end
                // SW
                2'b11: begin
                    ram_wen_sel[1:0] = i_waddr[1:0];
                    ram_wen_sel[3:2] = trunc_3to2(i_waddr[1:0] + 1'b1);
                    ram_wen_sel[5:4] = trunc_3to2(i_waddr[1:0] + 2'b10);
                    ram_wen_sel[7:6] = trunc_3to2(i_waddr[1:0] + 2'b11);
                    decoder_en[3:0]  = 4'b1111;
                end
                default: begin
                    ram_wen_sel = 8'h00;
                    ram_din_sel = 8'h00;
                    decoder_en  = 4'h0;
                end
            endcase

            case (i_waddr[1:0])
                2'b00: begin
                    ram_din_sel[1:0] = 2'b00;
                    ram_din_sel[3:2] = 2'b01;
                    ram_din_sel[5:4] = 2'b10;
                    ram_din_sel[7:6] = 2'b11;
                    waddr_0          = i_waddr >> 2;
                    waddr_1          = i_waddr >> 2;
                    waddr_2          = i_waddr >> 2;
                    waddr_3          = i_waddr >> 2;
                end
                2'b01: begin
                    ram_din_sel[3:2] = 2'b00;
                    ram_din_sel[5:4] = 2'b01;
                    ram_din_sel[7:6] = 2'b10;
                    ram_din_sel[1:0] = 2'b11;
                    waddr_1          = i_waddr >> 2;
                    waddr_2          = i_waddr >> 2;
                    waddr_3          = i_waddr >> 2;
                    waddr_0          = (i_waddr >> 2) + 1'b1;
                end
                2'b10: begin
                    ram_din_sel[5:4] = 2'b00;
                    ram_din_sel[7:6] = 2'b01;
                    ram_din_sel[1:0] = 2'b10;
                    ram_din_sel[3:2] = 2'b11;
                    waddr_2          = i_waddr >> 2;
                    waddr_3          = i_waddr >> 2;
                    waddr_0          = (i_waddr >> 2) + 1'b1;
                    waddr_1          = (i_waddr >> 2) + 1'b1;
                end
                2'b11: begin
                    ram_din_sel[7:6] = 2'b00;
                    ram_din_sel[1:0] = 2'b01;
                    ram_din_sel[3:2] = 2'b10;
                    ram_din_sel[5:4] = 2'b11;
                    waddr_3          = i_waddr >> 2;
                    waddr_0          = (i_waddr >> 2) + 1'b1;
                    waddr_1          = (i_waddr >> 2) + 1'b1;
                    waddr_2          = (i_waddr >> 2) + 1'b1;
                end
            endcase
        end
    end

    reg rd_reg;

    always @(posedge clk) begin
        if (i_rst) begin
            rd_reg <= 1'b0;
        end
        else begin
            rd_reg <= i_ren;
        end
    end


    // Read Logic
    always @(*) begin
        case (i_raddr[1:0])
            2'b00: begin
                raddr_0       = i_raddr >> 2;
                raddr_1       = i_raddr >> 2;
                raddr_2       = i_raddr >> 2;
                raddr_3       = i_raddr >> 2;
                o_dout[7:0]   = ram_0_dout;
                o_dout[15:8]  = ram_1_dout;
                o_dout[23:16] = ram_2_dout;
                o_dout[31:24] = ram_3_dout;
            end 
            2'b01: begin
                raddr_1       = i_raddr >> 2;
                raddr_2       = i_raddr >> 2;
                raddr_3       = i_raddr >> 2;
                raddr_0       = (i_raddr >> 2) + 1'b1;
                o_dout[7:0]   = ram_1_dout;
                o_dout[15:8]  = ram_2_dout;
                o_dout[23:16] = ram_3_dout;
                o_dout[31:24] = ram_0_dout;
            end
           2'b10: begin
                raddr_2       = i_raddr >> 2;
                raddr_3       = i_raddr >> 2;
                raddr_0       = (i_raddr >> 2) + 1'b1;
                raddr_1       = (i_raddr >> 2) + 1'b1;
                o_dout[7:0]   = ram_2_dout;
                o_dout[15:8]  = ram_3_dout;
                o_dout[23:16] = ram_0_dout;
                o_dout[31:24] = ram_1_dout;
            end
            2'b11: begin
                raddr_3       = i_raddr >> 2;
                raddr_0       = (i_raddr >> 2) + 1'b1;
                raddr_1       = (i_raddr >> 2) + 1'b1;
                raddr_2       = (i_raddr >> 2) + 1'b1;
                o_dout = {ram_2_dout, ram_1_dout, ram_0_dout, ram_3_dout};
            end 
        endcase

        if (~rd_reg) begin
            o_dout = {32{1'b0}};
        end
    end

endmodule