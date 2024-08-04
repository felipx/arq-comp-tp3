//! @title UART TOP
//! @file uart_top.v
//! @author Felipe Montero Bruni
//! @date 7-2024
//! @version 0.1

module uart_top
# (
    parameter NB_COUNTER   = 9,                            //! NB of baud generator counter reg
    parameter NB_DATA      = 8,                            //! NB of UART data reg
    parameter NB_FIFO_ADDR = 5                             //! NB of fifo's regs depth
) (
    // Outputs
    output wire                      o_tx      ,           //! UART Tx data output
    output wire                      o_tx_done ,           //! UART Tx done signal output
    output wire                      o_tx_empty,           //! FIFO Tx empty signal output
    output wire                      o_tx_full ,           //! FIFO Tx full output
    output wire [NB_DATA    - 1 : 0] o_rdata   ,           //! FIFO Rx data output
    output wire                      o_rx_done ,           //! UART Rx done signal output
    output wire                      o_rx_empty,           //! FIFO Rx empty signal output
    output wire                      o_rx_full ,           //! FIFO Rx full output
                                                 
    // Inputs                                   
    input  wire                        i_rx      ,         //! UART Rx data input
    input  wire                        i_tx_start,         //! UART Tx start signal input
    input  wire                        i_rd      ,         //! FIFO Rx read enable input
    input  wire                        i_wr      ,         //! FIFO Tx write enable input           
    input  wire [NB_DATA      - 1 : 0] i_wdata   ,         //! FIFO Tx write data input
    input  wire [NB_COUNTER   - 1 : 0] i_tick_cmp,         //! Value of baud rate generator at which to generate a tick
    input  wire                        i_rst     ,         //! Reset signal input
    input  wire                        clk                 //! Clock signal input
);

    //! Internal Signals
    reg rx_done_reg ;
    reg tx_start_reg;
    
    assign o_rx_done = rx_done_reg;
    

    wire                   baud_rate_gen_tick_to_uart   ;  //! Baud rate generator tick to uart connection
    wire [NB_DATA - 1 : 0] uart_rx_data_to_fifo_rx_wdata;  //! UART Rx data to FIFO Rx connection
    wire                   uart_rx_done                 ;  //! UART Rx done to FIDO Rx connection
    wire [NB_DATA - 1 : 0] fifo_tx_rdata_to_uart_tx     ;  //! FIFO Tx data to UART Tx connection
    
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
            .o_rx_done (uart_rx_done                 ),
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
            .o_rdata (o_rdata                      ),
            .o_empty (o_rx_empty                   ),
            .o_full  (o_rx_full                    ),
            .i_rd    (i_rd                         ),
            .i_wr    (uart_rx_done                 ),
            .i_wdata (uart_rx_data_to_fifo_rx_wdata),
            .i_rst   (i_rst                        ),
            .clk     (clk                          ) 
        );
    
    // UART TX
    uart_tx
    #(
        .NB_DATA (NB_DATA)
    )
        u_uart_tx
        (
            .o_tx       (o_tx                      ),
            .o_tx_done  (o_tx_done                 ),
            .i_data     (fifo_tx_rdata_to_uart_tx  ),
            .i_tx_start (tx_start_reg              ),
            .i_stick    (baud_rate_gen_tick_to_uart), 
            .i_rst      (i_rst                     ),
            .clk        (clk                       ) 
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
            .o_empty (o_tx_empty              ),
            .o_full  (o_tx_full               ),
            .i_rd    (tx_start_reg            ),
            .i_wr    (i_wr | i_tx_start       ),
            .i_wdata (i_wdata                 ),
            .i_rst   (i_rst                   ),
            .clk     (clk                     ) 
        );

    // rx_done output Logic
    always @(posedge clk) begin
        if (i_rst) begin
            rx_done_reg = 1'b0;
        end
        else begin
            if (uart_rx_done) begin
                rx_done_reg = 1'b1;
            end
            else begin
                rx_done_reg = 1'b0;
            end
        end
    end

    // tx_start Logic
    always @(posedge clk) begin
        if (i_rst) begin
            tx_start_reg <= 1'b0;
        end
        else begin
            if (i_tx_start) begin
                tx_start_reg <= 1'b1;
            end
            else begin
                tx_start_reg <= 1'b0;
            end
        end
    end

    

endmodule