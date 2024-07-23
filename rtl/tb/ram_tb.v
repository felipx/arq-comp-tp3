`timescale 1ns/100ps

module ram_tb ();

    parameter ADDR_WIDTH = 5            ;  //! Address width
    parameter DATA_DEPTH = 2**ADDR_WIDTH;
    parameter NB_WORD    = 32           ;
    parameter NB_RND     = 32           ;

    wire [NB_WORD - 1    : 0] dout  ;
    reg  [NB_WORD - 1    : 0] din  ;
    reg  [ADDR_WIDTH - 1 : 0] waddr;  
    reg  [ADDR_WIDTH - 1 : 0] raddr;
    reg  [1              : 0] wsize;
    reg                       w_en ;
    reg                       r_en ;

    reg [NB_RND - 1 : 0] rnd  ;
    reg                  i_rst;
    reg                  clk  ;

    // RAM
    memory
    #(
        .ADDR_WIDTH (ADDR_WIDTH)
    )
        u_memory
        (
            .o_dout  (dout ),
            .i_din   (din  ),
            .i_waddr (waddr),
            .i_raddr (raddr),
            .i_wsize (wsize),
            .i_wen   (w_en ),
            .i_ren   (r_en ),
            .i_rst   (i_rst),
            .clk     (clk  )
        );

    integer i;

    initial begin

        $display("Starting RAM Testbench");

        i_rst = 1'b0;
        clk   = 1'b0;
        r_en  = 1'b0;
        w_en  = 1'b0;
        din   = {NB_WORD{1'b0}};
        waddr = {ADDR_WIDTH{1'b0}};
        raddr = {ADDR_WIDTH{1'b0}};

        $display("SB write operation");

        #10 i_rst = 1'b1;
        #10 i_rst = 1'b0;

        w_en = 1'b1;
        for (i = 0; i < DATA_DEPTH; i = i + 1) begin
            din = 32'h0010 + i;
            waddr = i;
            wsize = 2'b01;
            #10;
        end

        $display("Read every byte");
        
        w_en = 1'b0;
        r_en = 1'b1;
        #10;
        for (i = 0; i < DATA_DEPTH; i = i + 4) begin
            raddr = i;
            #10;
            if (dout != (((8'h10 + 3 + i) << 24) + ((8'h10 + 2 + i) << 16) + ((8'h10 + 1 + i) << 8) + (8'h10 + i))) begin
                $display("Error: Wrong value read");
                $display("Expecting: %h , got: %h",8'h10 + i, dout[7:0]);
                $finish;
            end
        end 

        #20 $display("RAM Testbench finished");
        #20 $finish;
        
    end
    
    always #5 clk = ~clk;


endmodule