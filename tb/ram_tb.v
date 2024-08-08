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

    reg [NB_RND - 1 : 0] rnd_array [DATA_DEPTH - 1 : 0];
    
    reg i_rst;
    reg clk  ;

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

    integer i,j;

    initial begin

        $display("Starting RAM Testbench");

        j     = 0;
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
            wsize = 2'b01;
        
        for (i = 0; i < DATA_DEPTH; i = i + 1) begin
            #10 waddr = i; 
                rnd_array[i] = $random;
                din = rnd_array[i];    
        end

        $display("SB Read check");
        
        #10 w_en = 1'b0;
            r_en = 1'b1;
        
        
        for (i = 0; i < DATA_DEPTH; i = i + 4) begin
            raddr = i;
            #10;
            if (dout != (((rnd_array[i+3][7:0]) << 24) + ((rnd_array[i+2][7:0]) << 16) + ((rnd_array[i+1][7:0]) << 8) + (rnd_array[i][7:0]))) begin
                $display("Error: Wrong value read");
                $display("Expecting: %h , got: %h",(((rnd_array[i+3][7:0]) << 24) + ((rnd_array[i+2][7:0]) << 16) + ((rnd_array[i+1][7:0]) << 8) + (rnd_array[i][7:0])), dout);
                $finish;
            end
        end 

        $display("SH write operation");

        #10 w_en = 1'b1;
            r_en = 1'b0;
            wsize = 2'b10;
        
        
        for (i = 0; i < DATA_DEPTH ; i = i + 2) begin
            #10 waddr = i;
                rnd_array[j] = $random;
                din = rnd_array[j];
                j = j + 1;
        end

        $display("SH Read check");
        
        #10 w_en = 1'b0;
            r_en = 1'b1;
            j = 0;
        
        for (i = 0; i < DATA_DEPTH; i = i + 4) begin
            raddr = i;
            #10;
            if (dout != ((rnd_array[j+1][15:0] << 16) + rnd_array[j][15:0])) begin
                $display("Error: Wrong value read");
                $display("Expecting: %h , got: %h",((rnd_array[j+1][15:0] << 16) + rnd_array[j][15:0]), dout);
                $finish;
            end
            j = j + 2;
        end

        $display("SW write operation");

        #10 w_en = 1'b1;
            r_en = 1'b0;
            wsize = 2'b11;
            j = 0;
        
        for (i = 0; i < DATA_DEPTH; i = i + 4) begin
            #10 waddr = i;
                rnd_array[j] = $random;
                din = rnd_array[j];
                j = j + 1;
        end

        $display("SW Read check");
        
        #10 w_en = 1'b0;
            r_en = 1'b1;
            j = 0;
        
        for (i = 0; i < DATA_DEPTH; i = i + 4) begin
            raddr = i;
            #10;
            if (dout != rnd_array[j]) begin
                $display("Error: Wrong value read");
                $display("Expecting: %h , got: %h",rnd_array[j], dout);
                $finish;
            end
            j = j + 1;
        end

        #20 $display("RAM Testbench finished");
        #20 $finish;

        
    end
    
    always #5 clk = ~clk;


endmodule