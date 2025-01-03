`timescale 1ns/100ps

module stall_tb ();

    parameter NB_PC              = 32;  //! NB of Program Counter
    parameter NB_INSTRUCTION     = 32;  //! Size of each memory location
    parameter NB_DATA            = 32;  //! Size of Integer Base registers
    parameter IMEM_ADDR_WIDTH    = 6 ;  //! Instruction Memory address width
    parameter DMEM_ADDR_WIDTH    = 5 ;  //! Data Memory address width
    
    // UART Parameters
    parameter NB_UART_COUNTER    = 9;  //! NB of baud generator counter reg
    parameter NB_UART_DATA       = 8;  //! NB of UART data reg
    parameter NB_UART_ADDR       = 4;  //! NB of UART fifo's regs depth

    wire o_RsTx;
    wire  i_RsRx;
    reg  en;
    reg  i_rst;
    reg  clk;

    reg [7 : 0]           SOT;
    reg [7 : 0]           EOT;
    reg [7 : 0]           blk;
    reg [7 : 0]           blk_not;
    reg [7 : 0]           cksum;
    reg [NB_DATA - 1 : 0] i_imem_data [19 : 0];

    wire                       host_uart_tx_done;
    wire                       host_uart_rx_done;
    reg                        host_uart_tx_start;
    reg                        host_uart_rd;      
    reg                        host_uart_wr;       
    reg  [NB_UART_DATA - 1 : 0] host_uart_wdata;   
    wire [NB_UART_DATA - 1 : 0] host_uart_rdata;

    //! Connections
    wire cpu_rd_to_uart;
    wire cpu_wr_to_uart;
    wire [NB_UART_DATA - 1 : 0] cpu_wdata_to_uart;
    wire                        cpu_tx_start_to_uart;
    wire [NB_UART_DATA - 1 : 0] uart_rx_data_to_cpu;
    wire                        uart_rx_done_to_cpu;
    wire                        uart_tx_done_to_cpu;


    
    
    
    // CPU Subsystem
    cpu_subsystem
    #(
        .NB_PC           (NB_PC          ),
        .NB_INSTRUCTION  (NB_INSTRUCTION ),
        .NB_DATA         (NB_DATA        ),
        .NB_REG          (NB_DATA        ),
        .IMEM_ADDR_WIDTH (IMEM_ADDR_WIDTH),
        .DMEM_ADDR_WIDTH (DMEM_ADDR_WIDTH),
        .NB_UART_DATA    (NB_UART_DATA   )
    )
        u_cpu_subystem
        (
            .o_uart_tx_start (cpu_tx_start_to_uart),
            .o_uart_rd       (cpu_rd_to_uart      ),
            .o_uart_wr       (cpu_wr_to_uart      ),
            .o_uart_wdata    (cpu_wdata_to_uart   ),
            .i_uart_rx_data  (uart_rx_data_to_cpu ),
            .i_uart_rx_done  (uart_rx_done_to_cpu ),
            .i_uart_tx_done  (uart_tx_done_to_cpu ),
            .i_en            (en                  ),
            .i_rst           (i_rst               ),
            .clk             (clk                 )
        );
    
    // UART0
    uart_top
    #(
        .NB_COUNTER   (NB_UART_COUNTER),
        .NB_DATA      (NB_UART_DATA   ),
        .NB_FIFO_ADDR (NB_UART_ADDR   )
    )
        u_uart_0
        (
            .o_tx       (o_RsTx              ),
            .o_tx_done  (uart_tx_done_to_cpu ),
            .o_tx_empty (                    ),
            .o_tx_full  (                    ),
            .o_rdata    (uart_rx_data_to_cpu ),
            .o_rx_done  (uart_rx_done_to_cpu ),
            .o_rx_empty (                    ),
            .o_rx_full  (                    ),     
            .i_rx       (i_RsRx              ),
            .i_tx_start (cpu_tx_start_to_uart),
            .i_rd       (cpu_rd_to_uart      ),
            .i_wr       (cpu_wr_to_uart      ),
            .i_wdata    (cpu_wdata_to_uart   ),
            .i_tick_cmp (9'h146              ),
            .i_rst      (i_rst               ),
            .clk        (clk                 )
        );


    //
    uart_top
    #(
        .NB_COUNTER   (NB_UART_COUNTER),
        .NB_DATA      (NB_UART_DATA   ),
        .NB_FIFO_ADDR (7              )
    )
        u_uart_host
        (
            .o_tx       (i_RsRx              ),
            .o_tx_done  (host_uart_tx_done   ),
            .o_tx_empty (                    ),
            .o_tx_full  (                    ),
            .o_rdata    (host_uart_rdata     ),
            .o_rx_done  (host_uart_rx_done   ),
            .o_rx_empty (                    ),
            .o_rx_full  (                    ),     
            .i_rx       (o_RsTx              ),
            .i_tx_start (host_uart_tx_start  ),
            .i_rd       (host_uart_rd        ),
            .i_wr       (host_uart_wr        ),
            .i_wdata    (host_uart_wdata     ),
            .i_tick_cmp (9'h146              ),
            .i_rst      (i_rst               ),
            .clk        (clk                 )
        );

    integer i, j;
    integer TBAUD = 52083;

    initial begin

        clk   = 1'b0;
        en    = 1'b0;
        i_rst = 1'b0;

        host_uart_tx_start = 1'b0;
        host_uart_rd       = 1'b0;      
        host_uart_wr       = 1'b0;      
        host_uart_wdata    = 8'h00;   

        SOT     = 8'h01;
        EOT     = 8'h04;
        blk     = 8'h01;
        blk_not = 8'hFE;
        cksum   = 8'h00;

        // addi x1, x0, 0xC
        i_imem_data[0] = 32'b000000001100_00000_000_00001_0010011;

        // addi x2, x0, 0xFFF
        i_imem_data[1] = 32'b111111111111_00000_000_00010_0010011;

        // sw x2, 0x1C(x0)
        i_imem_data[2] = 32'b0000000_00010_00000_010_11100_0100011;

        // addi x3, x0, 0xEFF
        i_imem_data[3] = 32'b111011111111_00000_000_00011_0010011;

        // addi x4, x0, 0x444
        i_imem_data[4] = 32'b010001000100_00000_000_00100_0010011;
        
        // addi x5, x5, 0xFE5
        i_imem_data[5] = 32'b111111100101_00101_000_00101_0010011;

        // lw x6, 0x10(x1)
        i_imem_data[6] = 32'b000000010000_00001_010_00110_0000011;
        
        // and x4, x6, x5
        i_imem_data[7] = 32'b0000000_00101_00110_111_00100_0110011; // stall
        
        // or x8, x2, x6
        i_imem_data[8] = 32'b0000000_00110_00010_110_01000_0110011;
        
        // add x14, x6, x4
        i_imem_data[9] = 32'b0000000_00100_00110_000_01110_0110011;
        
        // sub x2, x6, x3
        i_imem_data[10] = 32'b0100000_00011_00110_000_00010_0110011;
        

        #20 i_rst = 1'b1;
        #20 i_rst = 1'b0;
            en    = 1'b1;

        // Send SOT
        #10 host_uart_wdata    = SOT;
        #10 host_uart_tx_start = 1'b1;
        #10 host_uart_tx_start = 1'b0;
        while (host_uart_tx_done != 1'b1) begin
            #10;
        end
        
        // Send blk
        #10 host_uart_wdata    = blk;
        #10 host_uart_tx_start = 1'b1;
        #10 host_uart_tx_start = 1'b0;
        while (host_uart_tx_done != 1'b1) begin
            #10;
        end

        // send ~blk
        #10 host_uart_wdata    = blk_not;
        #10 host_uart_tx_start = 1'b1;
        #10 host_uart_tx_start = 1'b0;
        while (host_uart_tx_done != 1'b1) begin
            #10;
        end


        for (j = 0; j < 11 ; j = j + 1) begin
        
            #10 host_uart_wdata    = i_imem_data[j][7:0];
            #10 host_uart_tx_start = 1'b1;
            #10 host_uart_tx_start = 1'b0;
            while (host_uart_tx_done != 1'b1) begin
                #10;
            end
            
            #10 host_uart_wdata    = i_imem_data[j][15:8];
            #10 host_uart_tx_start = 1'b1;
            #10 host_uart_tx_start = 1'b0;
            while (host_uart_tx_done != 1'b1) begin
                #10;
            end
    
            #10 host_uart_wdata    = i_imem_data[j][23:16];
            #10 host_uart_tx_start = 1'b1;
            #10 host_uart_tx_start = 1'b0;
            while (host_uart_tx_done != 1'b1) begin
                #10;
            end
    
            #10 host_uart_wdata    = i_imem_data[j][31:24];
            #10 host_uart_tx_start = 1'b1;
            #10 host_uart_tx_start = 1'b0;
            while (host_uart_tx_done != 1'b1) begin
                #10;
            end

            cksum = cksum + i_imem_data[j][7:0] + i_imem_data[j][15:8] + i_imem_data[j][23:16] + i_imem_data[j][31:24];

        end

        // Send padding
        for (j = 0; j < 84 ; j = j + 1) begin
            #10 host_uart_wdata = 8'h1A;
        #10 host_uart_tx_start = 1'b1;
        #10 host_uart_tx_start = 1'b0;
        while (host_uart_tx_done != 1'b1) begin
            #10;
        end

            cksum = cksum + 8'h1A;
        end

        // Send cksum
        #10 host_uart_wdata    = cksum;
        #10 host_uart_tx_start = 1'b1;
        #10 host_uart_tx_start = 1'b0;
        while (host_uart_tx_done != 1'b1) begin
            #10;
        end

        // Send EOT
        #10 host_uart_wdata    = EOT;
        #10 host_uart_tx_start = 1'b1;
        #10 host_uart_tx_start = 1'b0;
        while (host_uart_tx_done != 1'b1) begin
            #10;
        end

        #(TBAUD*8)

        // Send 0x01
        #10 host_uart_wdata    = 8'h01;
        #10 host_uart_tx_start = 1'b1;
        #10 host_uart_tx_start = 1'b0;
        while (host_uart_tx_done != 1'b1) begin
            #10;
        end
        
        #TBAUD;
        

        #20 $display("Stall Testbench finished");
        #20 $finish;
        
    end
    
    always #5 clk = ~clk;
    
endmodule