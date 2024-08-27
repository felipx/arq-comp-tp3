module top
#(
    parameter NB_PC           = 32,  //! NB of Program Counter
    parameter NB_INSTRUCTION  = 32,  //! Size of each memory location
    parameter NB_DATA         = 32,  //! Size of Integer Base registers
    parameter IMEM_ADDR_WIDTH = 10,  //! Instruction Memory address width
    parameter DMEM_ADDR_WIDTH = 10,  //! Data Memory address width       
    
    // UART Parameters
    parameter NB_UART_COUNTER = 32,  //! NB of baud generator counter reg
    parameter NB_UART_DATA    = 8 ,  //! NB of UART data reg
    parameter NB_UART_ADDR    = 7    //! NB of UART fifo's regs depth
                                 
) (
    // Ouputs
    output wire o_RsTx,
    
    // Inputs
    input  wire i_RsRx,
    input  wire i_rst ,
    input  wire i_clk
);
    
    //! Connections
    wire                        clk                 ;
    wire                        pll_locked          ;
    wire                        cpu_rd_to_uart      ;
    wire                        cpu_wr_to_uart      ;
    wire [NB_UART_DATA - 1 : 0] cpu_wdata_to_uart   ;
    wire                        cpu_tx_start_to_uart;
    wire [NB_UART_DATA - 1 : 0] uart_rx_data_to_cpu ;
    wire                        uart_rx_done_to_cpu ;
    wire                        uart_tx_done_to_cpu ;
    wire                        rsRx                ;
    wire                        rst                 ;
    
    // MMCM or PLL
    mmcm
        u_mmcm_0
        (
            .clk_out1_0 (clk       ),
            .locked_0   (pll_locked),
            .clk_in1_0  (i_clk     ),
            .reset_0    (i_rst     )
        );

    // Reset signal 2-flip-flop synchronizer
    s2ff
        u_rst_s2ff
        (
            .async_in (i_rst),
            .sync_out (rst  ), 
            .clk      (clk  ) 
        );

    // UART Rx signal 2-flip-flop synchronizer
    s2ff
        u_uart_rx_s2ff
        (
            .async_in (i_RsRx),
            .sync_out (rsRx  ), 
            .clk      (clk   ) 
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
            .i_en            (pll_locked          ),
            .i_rst           (rst                 ),
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
            .i_rx       (rsRx                ),
            .i_tx_start (cpu_tx_start_to_uart),
            .i_rd       (cpu_rd_to_uart      ),
            .i_wr       (cpu_wr_to_uart      ),
            .i_wdata    (cpu_wdata_to_uart   ),
            .i_tick_cmp (32'd27              ),
            .i_rst      (rst                 ),
            .clk        (clk                 )
        );
    
    ///////////////////////////////////////////////
    // UART TICK COUNTER VALUES                  //
    // ------------------------------------------//
    // tickVal = fclk/(16*baudRate)              //
    // ------------------------------------------//
    // fclk (MHz) | baudRate | tickVal |         //
    //     50        19200       163             //
    //     50       115200        27             //
    //    100         9600       651             //
    //    100        19200       326             //
    //    100       115200        54             //
    ///////////////////////////////////////////////

endmodule