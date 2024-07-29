module top
#(
    parameter NB_PC              = 32,  //! NB of Program Counter
    parameter NB_INSTRUCTION     = 32,  //! Size of each memory location
    parameter NB_DATA            = 32,  //! Size of Integer Base registers
    parameter IMEM_ADDR_WIDTH    = 8 ,  //! Instruction Memory address width
    parameter DMEM_ADDR_WIDTH    = 5 ,  //! Data Memory address width

    // UART Parameters
    parameter NB_UART_COUNTER    = 9 ,  //! NB of baud generator counter reg
    parameter NB_UART_DATA       = 9 ,  //! NB of UART data reg
    parameter NB_FIFO_ADDR       = 5    //! NB of fifo's regs depth
) (
    // Ouputs
    output wire o_RsTx,

    // Inputs
    input  wire i_RsRx,
    input  wire i_rst ,
    input  wire clk
);
    
    // CPU Subsystem
    cpu_subsystem
    #(
        .NB_PC           (NB_PC          ),
        .NB_INSTRUCTION  (NB_INSTRUCTION ),
        .NB_DATA         (NB_DATA        ),
        .IMEM_ADDR_WIDTH (IMEM_ADDR_WIDTH),
        .DMEM_ADDR_WIDTH (DMEM_ADDR_WIDTH)
    )
        u_cpu_subystem
        (
            .i_imem_data  (),
            .i_imem_waddr (),
            .i_imem_wen   (),
            .i_mem_wsize  (),
            .i_en         (),
            .i_rst        (i_rst),
            .clk          (clk  )
        );
    
    // UART0
    uart_top
    #(
        .NB_COUNTER   (NB_UART_COUNTER),
        .NB_DATA      (NB_UART_DATA   ),
        .NB_FIFO_ADDR (NB_FIFO_ADDR   )
    )
        u_uart_0
        (
            .o_tx       (o_RsTx),
            .o_tx_done  (      ),
            .o_tx_empty (      ),
            .o_tx_full  (      ),
            .o_rdata    (      ),
            .o_rx_empty (      ),
            .o_rx_full  (      ),     
            .i_rx       (i_RsRx),
            .i_tx_start (      ),
            .i_ren      (      ),
            .i_wen      (      ),
            .i_wdata    (      ),
            .i_tick_cmp (9'h146),
            .i_rst      (i_rst ),
            .clk        (clk   )
        );
    
endmodule