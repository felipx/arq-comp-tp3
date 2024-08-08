`timescale 1ns/100ps

module forwarding_tb ();
    
    parameter NB_PC              = 32;  //! NB of Program Counter
    parameter NB_INSTRUCTION     = 32;  //! Size of each memory location
    parameter NB_DATA            = 32;  //! Size of Integer Base registers
    parameter IMEM_ADDR_WIDTH    = 8 ;  //! Instruction Memory address width
    parameter DMEM_ADDR_WIDTH    = 5 ;  //! Data Memory address width

    localparam IMEM_DATA_DEPTH = 2**IMEM_ADDR_WIDTH;

    reg i_en ;
    reg i_rst;
    reg clk  ;
    
    // IMEM inputs
    reg [NB_DATA         - 1 : 0] i_imem_data ;
    reg [IMEM_ADDR_WIDTH - 1 : 0] i_imem_waddr;
    reg                           i_imem_wen  ;
    reg [1 : 0]                   i_imem_wsize;
    
    // CPU Subsystem
    cpu_subsystem
    #()
        u_cpu_subystem
        (
            .i_imem_data  (i_imem_data ),
            .i_imem_waddr (i_imem_waddr),
            .i_mem_wsize  (i_imem_wsize),
            .i_imem_wen   (i_imem_wen  ),
            .i_en         (i_en        ),
            .i_rst        (i_rst       ),
            .clk          (clk         )
        );

    

    initial begin

        $display("Starting Forwarding Testbench");

        clk   = 1'b0;
        i_rst = 1'b0;
        i_en  = 1'b0;

        i_imem_data  = {NB_INSTRUCTION{1'b0}};
        i_imem_waddr = {IMEM_DATA_DEPTH{1'b0}};
        i_imem_wen   = 1'b0;
        i_imem_wsize = 2'b00;

        #20 i_rst = 1'b1;
        #20 i_rst = 1'b0;

        $display("Load instructions in imem");

        i_imem_wsize = 2'b11;

        // addi x1, x1, 0x1
        i_imem_data  = 32'b000000000001_00001_000_00001_0010011;
        i_imem_waddr = i_imem_waddr + 1'b0;

        #10 i_imem_wen = 1'b1;

        // addi x2, x2, 0x2
        #10 i_imem_data  = 32'b000000000010_00010_000_00010_0010011;
            i_imem_waddr = i_imem_waddr + 4'd4;

        // addi x3, x3, 0x3
        #10 i_imem_data  = 32'b000000000011_00011_000_00011_0010011;
            i_imem_waddr = i_imem_waddr + 4'd4;

        // addi x4, x4, 0x4
        #10 i_imem_data  = 32'b000000000100_00100_000_00100_0010011;
            i_imem_waddr = i_imem_waddr + 4'd4;

        // addi x5, x5, 0x5
        #10 i_imem_data  = 32'b000000000101_00101_000_00101_0010011;
            i_imem_waddr = i_imem_waddr + 4'd4;

        // addi x6, x6, 0x6
        #10 i_imem_data  = 32'b000000000110_00110_000_00110_0010011;
            i_imem_waddr = i_imem_waddr + 4'd4;

        // addi x7, x7, 0x7
        #10 i_imem_data  = 32'b000000000111_00111_000_00111_0010011;
            i_imem_waddr = i_imem_waddr + 4'd4;

        // addi x8, x8, 0x8
        #10 i_imem_data  = 32'b000000001000_01000_000_01000_0010011;
            i_imem_waddr = i_imem_waddr + 4'd4;

        // addi x9, x9, 0x9
        #10 i_imem_data  = 32'b000000001001_01001_000_01001_0010011;
            i_imem_waddr = i_imem_waddr + 4'd4;

        // addi x10, x10, 0xA
        #10 i_imem_data  = 32'b000000001010_01010_000_01010_0010011;
            i_imem_waddr = i_imem_waddr + 4'd4;

        // addi x11, x11, 0xB
        #10 i_imem_data  = 32'b000000001011_01011_000_01011_0010011;
            i_imem_waddr = i_imem_waddr + 4'd4;

        // addi x12, x12, 0xC
        #10 i_imem_data  = 32'b000000001100_01100_000_01100_0010011;
            i_imem_waddr = i_imem_waddr + 4'd4;

        // addi x13, x13, 0xD
        #10 i_imem_data  = 32'b000000001101_01101_000_01101_0010011;
            i_imem_waddr = i_imem_waddr + 4'd4;

        // addi x14, x14, 0xE
        #10 i_imem_data  = 32'b000000001110_01110_000_01110_0010011;
            i_imem_waddr = i_imem_waddr + 4'd4;

        // addi x15, x15, 0xF
        #10 i_imem_data  = 32'b000000001111_01111_000_01111_0010011;
            i_imem_waddr = i_imem_waddr + 4'd4;


        // sub x2, x3, x1
        #10 i_imem_data  = 32'b0100000_00001_00011_000_00010_0110011;
            i_imem_waddr = i_imem_waddr + 4'd4;

        // and x12, x2, x5
        #10 i_imem_data  = 32'b0000000_00101_00010_111_01100_0110011;
            i_imem_waddr = i_imem_waddr + 4'd4;

        // or x13, x6, x2
        #10 i_imem_data  = 32'b0000000_00010_00110_110_01101_0110011;
            i_imem_waddr = i_imem_waddr + 4'd4;

        // add x14, x2, x2
        #10 i_imem_data  = 32'b0000000_00010_00010_000_01110_0110011;
            i_imem_waddr = i_imem_waddr + 4'd4;

        // sw x15, 10(x2)
        #10 i_imem_data  = 32'b0000000_01111_00010_010_01010_0100011;
            i_imem_waddr = i_imem_waddr + 4'd4; 

        #10 i_imem_wen = 1'b0;

            i_en = 1'b1; 

        #1000;


        #20 $display("IF/ID Stages Testbench finished");
        #20 $finish;
    end

    always #5 clk = ~clk;

endmodule