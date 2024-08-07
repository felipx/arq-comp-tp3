module top
#(
    parameter NB_PC           = 32,  //! NB of Program Counter
    parameter NB_INSTRUCTION  = 32,  //! Size of each memory location
    parameter NB_DATA         = 32,  //! Size of Integer Base registers
    parameter IMEM_ADDR_WIDTH = 7  ,  //! Instruction Memory address width
    parameter DMEM_ADDR_WIDTH = 7 ,  //! Data Memory address width       

    // UART Parameters
    parameter NB_UART_COUNTER = 9 ,  //! NB of baud generator counter reg
    parameter NB_UART_DATA    = 8 ,  //! NB of UART data reg
    parameter NB_UART_ADDR    = 7    //! NB of UART fifo's regs depth
                                      
    //parameter NB_LEDS         = 4 ,  // edu-ciaa board
    //parameter NB_OUT          = 16   // edu-ciaa board
) (
    // Ouputs
    //output wire [NB_OUT  - 1 : 0] B1    , // edu-ciaa board
    //output wire [NB_LEDS - 1 : 0] o_led , // edu-ciaa board
    output wire                   o_RsTx,

    // Inputs
    input  wire i_RsRx,
    input  wire i_rst ,
    input  wire i_clk    // i_clk if pll is used else clk
);
    
    wire clk; // if pll is used

    //! Connections
    wire                        cpu_rd_to_uart;
    wire                        cpu_wr_to_uart;
    wire [NB_UART_DATA - 1 : 0] cpu_wdata_to_uart;
    wire                        cpu_tx_start_to_uart;
    wire [NB_UART_DATA - 1 : 0] uart_rx_data_to_cpu;
    wire                        uart_rx_done_to_cpu;
    wire                        uart_tx_done_to_cpu;
    
    pll
        u_ppl_0
        (
            .clk_out1_0 (clk  ),
            .locked_0   (     ),
            .clk_in1_0  (i_clk),
            .reset_0    (i_rst)
        );
    
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
            .i_en            (1'b1                ),
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
            .i_tick_cmp (9'd163              ), // 163 -> fBaud = 19200, clk = 50 Mhz
            .i_rst      (i_rst               ),
            .clk        (clk                 )
        );
    
endmodule