//! @title UART TOP
//! @file uart_top.v
//! @author Felipe Montero Bruni
//! @date 7-2024
//! @version 0.1

module uart_top
# (
    parameter NB_COUNTER   = 9,  //! NB of baud generator counter reg
    parameter NB_DATA      = 8,  //! NB of UART data reg
    parameter NB_FIFO_ADDR = 4   //! NB of fifo's regs depth
) (
    // Outputs
    output wire o_tx,  //! UART data output
    
    // Inputs
    input  wire [NB_COUNTER - 1 : 0] i_tick_cmp,  //! Value of baud rate generator at which to generate a tick
    input  wire                      i_rx      ,  //! UART data input
    input  wire                      i_rst     ,  //! Reset signal input
    input  wire                      clk       ,  //! Clock signal input
);
    // Internal Signals
    wire                   baud_rate_gen_tick_to_uart   ;

    wire [NB_DATA - 1 : 0] uart_rx_data_to_fifo_rx_wdata;
    wire                   uart_rx_done_to_fifo_rx_wr   ;

    wire [NB_DATA - 1 : 0] fifo_tx_rdata_to_uart_tx     ;
    
    // Baud Rate Generator
    counter
    #(
        .NB_COUNTER (NB_COUNTER)
    )
        u_baud_rate_gen
        (
            .o_counter  (                          ), // Not used
            .o_tick     (baud_rate_gen_tick_to_uart),
            .i_tick_cmp (i_tick_cmp                ),
            .i_rst      (i_rst                     ),
            .clk        (clk                       ) 
        );
    
    // UART RX
    uart_rx
    #(
        .NB_DATA (NB_DATA)
    )
        u_uart_rx
        (
            .o_data    (uart_rx_data_to_fifo_rx_wdata),
            .o_rx_done (uart_rx_done_to_fifo_rx_wr   ),
            .i_rx      (i_rx                         ),
            .i_stick   (baud_rate_gen_tick_to_uart   ),
            .i_rst     (i_rst                        ),
            .clk       (clk                          )
        );
    
    // FIFO RX
    fifo
    #(
        .NB_DATA (NB_DATA     ),
        .NB_ADDR (NB_FIFO_ADDR)
    )
        u_uart_rx_fifo
        (
            .o_rdata (                             ), //TODO
            .o_empty (                             ), //TODO
            .o_full  (                             ), //TODO
            .i_rd    (                             ), //TODO
            .i_wr    (uart_rx_done_to_fifo_rx_wr   ),
            .i_wdata (uart_rx_data_to_fifo_rx_wdata),
            .i_rst   (i_rst                        ),
            .clk     (clk                          ) 
        );
    
    // UART TX
    uart_tx
    (
        .NB_DATA (NB_DATA)
    )
        u_uart_tx
        (
            .o_tx       (o_tx                    ),
            .o_tx_done  (                        ), //TODO
            .i_data     (fifo_tx_rdata_to_uart_tx),
            .i_tx_start (                        ), //TODO
            .i_stick    (                        ), //TODO
            .i_rst      (i_rst                   ),
            .clk        (clk                     ) 
        );
    
    // FIFO TX
    fifo
    #(
        .NB_DATA (NB_DATA     ),
        .NB_ADDR (NB_FIFO_ADDR)
    )
        u_uart_tx_fifo
        (
            .o_rdata (fifo_tx_rdata_to_uart_tx),
            .o_empty (                        ), //TODO
            .o_full  (                        ), //TODO
            .i_rd    (                        ), //TODO
            .i_wr    (                        ), //TODO
            .i_wdata (                        ),
            .i_rst   (i_rst                   ),
            .clk     (clk                     ) 
        );

endmodule