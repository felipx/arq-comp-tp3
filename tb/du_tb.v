`timescale 1ns/100ps

module du_tb ();

    parameter NB_PC              = 32;  //! NB of Program Counter
    parameter NB_INSTRUCTION     = 32;  //! Size of each memory location
    parameter NB_DATA            = 32;  //! Size of Integer Base registers
    parameter IMEM_ADDR_WIDTH    = 7 ;  //! Instruction Memory address width
    parameter DMEM_ADDR_WIDTH    = 5 ;  //! Data Memory address width
    
    // UART Parameters
    parameter NB_UART_COUNTER    = 9;  //! NB of baud generator counter reg
    parameter NB_UART_DATA       = 8;  //! NB of UART data reg
    parameter NB_UART_ADDR       = 4;  //! NB of UART fifo's regs depth

    wire o_RsTx;
    reg  i_RsRx;
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
    reg [NB_UART_DATA - 1 : 0] host_uart_wdata;   

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
            .o_tx       (                    ),
            .o_tx_done  (host_uart_tx_done   ),
            .o_tx_empty (                    ),
            .o_tx_full  (                    ),
            .o_rdata    (                    ),
            .o_rx_done  (host_uart_rx_done   ),
            .o_rx_empty (                    ),
            .o_rx_full  (                    ),     
            .i_rx       (o_RsTx              ),
            .i_tx_start (host_uart_tx_start  ),
            .i_rd       (host_uart_rd        ),
            .i_wr       (host_uart_wr        ),
            .i_wdata    (cpu_wdata_to_uart   ),
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
        i_RsRx = 1'b1;

        host_uart_tx_start = 1'b0;
        host_uart_rd       = 1'b0;      
        host_uart_wr       = 1'b0;      
        host_uart_wdata    = 8'h00;   

        SOT     = 8'h01;
        EOT     = 8'h04;
        blk     = 8'h01;
        blk_not = 8'hFE;
        cksum   = 8'h00;

        // addi x1, x1, 0x1
        i_imem_data[0] = 32'b000000000001_00001_000_00001_0010011;

        // addi x2, x2, 0x2
        i_imem_data[1] = 32'b000000000010_00010_000_00010_0010011;

        // addi x3, x3, 0x3
        i_imem_data[2] = 32'b000000000011_00011_000_00011_0010011;

        // addi x4, x4, 0x4
        i_imem_data[3] = 32'b000000000100_00100_000_00100_0010011;
        
        // addi x5, x5, 0x5
        i_imem_data[4] = 32'b000000000101_00101_000_00101_0010011;
        
        // addi x6, x6, 0x6
        i_imem_data[5] = 32'b000000000110_00110_000_00110_0010011;
        
        // addi x7, x7, 0x7
        i_imem_data[6] = 32'b000000000111_00111_000_00111_0010011;
        
        // addi x8, x8, 0x8
        i_imem_data[7] = 32'b000000001000_01000_000_01000_0010011;
        
        // addi x9, x9, 0x9
        i_imem_data[8] = 32'b000000001001_01001_000_01001_0010011;
        
        // addi x10, x10, 0xA
        i_imem_data[9] = 32'b000000001010_01010_000_01010_0010011;
        
        // addi x11, x11, 0xB
        i_imem_data[10] = 32'b000000001011_01011_000_01011_0010011;
        
        // addi x12, x12, 0xC
        i_imem_data[11] = 32'b000000001100_01100_000_01100_0010011;
        
        // addi x13, x13, 0xD
        i_imem_data[12] = 32'b000000001101_01101_000_01101_0010011;
        
        // addi x14, x14, 0xE
        i_imem_data[13] = 32'b000000001110_01110_000_01110_0010011;
        
        // addi x15, x15, 0xF
        i_imem_data[14] = 32'b000000001111_01111_000_01111_0010011;
        
        // sub x2, x3, x1
        i_imem_data[15] = 32'b0100000_00001_00011_000_00010_0110011;
        
        // and x12, x2, x5
        i_imem_data[16] = 32'b0000000_00101_00010_111_01100_0110011;
        
        // or x13, x6, x2
        i_imem_data[17] = 32'b0000000_00010_00110_110_01101_0110011;
        
        // add x14, x2, x2
        i_imem_data[18] = 32'b0000000_00010_00010_000_01110_0110011;
        
        // sw x1, 10(x0)
        i_imem_data[19] = 32'b0000000_00001_00000_010_01010_0100011;
        

        #20 i_rst = 1'b1;
        #20 i_rst = 1'b0;
            en    = 1'b1;

        #10 i_RsRx = 1'b0; // start
        for (i = 0; i < 8; i = i + 1) begin
            #TBAUD i_RsRx = (SOT >> i) & 1'b1; 
        end
        #TBAUD i_RsRx = 1'b1; // stop

        #TBAUD i_RsRx = 1'b0; // start
        for (i = 0; i < 8; i = i + 1) begin
            #TBAUD i_RsRx = (blk >> i) & 1'b1; 
        end
        #TBAUD i_RsRx = 1'b1; // stop

        #TBAUD i_RsRx = 1'b0; // start
        for (i = 0; i < 8; i = i + 1) begin
            #TBAUD i_RsRx = (blk_not >> i) & 1'b1; 
        end
        #TBAUD i_RsRx = 1'b1; // stop


        for (j = 0; j < 20 ; j = j + 1) begin
            
            //$display("Sending %h", i_imem_data[j][7:0]);
            
            #TBAUD i_RsRx = 1'b0; // start
            for (i = 0; i < 8; i = i + 1) begin
                #TBAUD i_RsRx = (i_imem_data[j][7:0] >> i) & 1'b1; 
            end
            #TBAUD i_RsRx = 1'b1; // stop
    
            #TBAUD i_RsRx = 1'b0; // start
            for (i = 0; i < 8; i = i + 1) begin
                #TBAUD i_RsRx = (i_imem_data[j][15:8] >> i) & 1'b1; 
            end
            #TBAUD i_RsRx = 1'b1; // stop
    
            #TBAUD i_RsRx = 1'b0; // start
            for (i = 0; i < 8; i = i + 1) begin
                #TBAUD i_RsRx = (i_imem_data[j][23:16] >> i) & 1'b1; 
            end
            #TBAUD i_RsRx = 1'b1; // stop
    
            #TBAUD i_RsRx = 1'b0; // start
            for (i = 0; i < 8; i = i + 1) begin
                #TBAUD i_RsRx = (i_imem_data[j][31:24] >> i) & 1'b1; 
            end
            #TBAUD i_RsRx = 1'b1; // stop

            cksum = cksum + i_imem_data[j][7:0] + i_imem_data[j][15:8] + i_imem_data[j][23:16] + i_imem_data[j][31:24];

        end

        // Send padding
        for (j = 0; j < 48 ; j = j + 1) begin
            #TBAUD i_RsRx = 1'b0; // start
            for (i = 0; i < 8; i = i + 1) begin
                #TBAUD i_RsRx = (8'h1A >> i) & 1'b1; 
            end
            #TBAUD i_RsRx = 1'b1; // stop

            cksum = cksum + 8'h1A;
        end

        // Send cksum
        #TBAUD i_RsRx = 1'b0; // start
        for (i = 0; i < 8; i = i + 1) begin
            #TBAUD i_RsRx = (cksum >> i) & 1'b1; 
        end
        #TBAUD i_RsRx = 1'b1; // stop

        // Send EOT
        #TBAUD i_RsRx = 1'b0; // start
        for (i = 0; i < 8; i = i + 1) begin
            #TBAUD i_RsRx = (EOT >> i) & 1'b1; 
        end
        #TBAUD i_RsRx = 1'b1; // stop

        #(TBAUD*8)

        // Send 0x01
        #TBAUD i_RsRx = 1'b0; // start
        for (i = 0; i < 8; i = i + 1) begin
            #TBAUD i_RsRx = (8'h01 >> i) & 1'b1; 
        end
        #TBAUD i_RsRx = 1'b1; // stop

        #(TBAUD*1536);
        
        //#28300 en = 1'b0;
        
        //#10 en = 1'b1;
        
        // Send 0x0A
        #TBAUD i_RsRx = 1'b0; // start
        for (i = 0; i < 8; i = i + 1) begin
            #TBAUD i_RsRx = (8'h0A >> i) & 1'b1; 
        end
        #TBAUD i_RsRx = 1'b1; // stop
        
        // Send 0x00
        #TBAUD i_RsRx = 1'b0; // start
        for (i = 0; i < 8; i = i + 1) begin
            #TBAUD i_RsRx = (8'h00 >> i) & 1'b1; 
        end
        #TBAUD i_RsRx = 1'b1; // stop
        
        // Send 0x00
        #TBAUD i_RsRx = 1'b0; // start
        for (i = 0; i < 8; i = i + 1) begin
            #TBAUD i_RsRx = (8'h00 >> i) & 1'b1; 
        end
        #TBAUD i_RsRx = 1'b1; // stop
        
        // Send 0x00
        #TBAUD i_RsRx = 1'b0; // start
        for (i = 0; i < 8; i = i + 1) begin
            #TBAUD i_RsRx = (8'h00 >> i) & 1'b1; 
        end
        #TBAUD i_RsRx = 1'b1; // stop
        
        #(TBAUD*1536);
        

        #20 $display("DU Testbench finished");
        #20 $finish;
        
    end
    
    always #5 clk = ~clk;
    
endmodule