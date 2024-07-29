module cpu_subsystem
#(
    parameter NB_PC              = 32,  //! NB of Program Counter
    parameter NB_INSTRUCTION     = 32,  //! Size of each memory location
    parameter NB_REG             = 32,  //! Size of Integer Base registers
    parameter IMEM_ADDR_WIDTH    = 8 ,  //! Instruction Memory address width
    parameter DMEM_ADDR_WIDTH    = 5 ,  //! Data Memory address width
    parameter NB_UART_DATA       = 8 
) (
    // Outputs
    output wire                        o_uart_tx_start,
    output wire                        o_uart_rd      ,
    output wire                        o_uart_wr      ,
    output wire [NB_UART_DATA - 1 : 0] o_uart_wdata   , 

    // Inputs
    input wire i_uart_rx_data,
    input wire i_uart_rx_done,
    input wire i_en          ,
    input wire i_rst         ,
    input wire clk            
);

    //! Localparameters
    localparam NB_BYTE = 8;

    //! Connections
    wire debug_unit_cpu_en;
    wire [NB_INSTRUCTION  - 1 : 0] du_imem_data_to_cpu;
    wire [IMEM_ADDR_WIDTH - 1 : 0] du_imem_waddr_to_cpu;
    wire [1 : 0]                   du_imem_wsize_to_cpu;
    wire                           du_imem_wen_to_cpu;
    

    // CPU Core
    cpu_core
    #(
        .NB_PC           (NB_PC          ),
        .NB_INSTRUCTION  (NB_INSTRUCTION ),
        .NB_DATA         (NB_REG         ),
        .IMEM_ADDR_WIDTH (IMEM_ADDR_WIDTH),
        .DMEM_ADDR_WIDTH (DMEM_ADDR_WIDTH)
    )
        u_cpu
        (
            .i_imem_data  (du_imem_data_to_cpu     ),
            .i_imem_waddr (du_imem_waddr_to_cpu    ),
            .i_mem_wsize  (du_imem_wsize_to_cpu    ),
            .i_imem_wen   (du_imem_wen_to_cpu      ),
            .i_en         (i_en & debug_unit_cpu_en),
            .i_rst        (i_rst                   ),
            .clk          (clk                     )
        );
    
    // Debug Unit
    debug_unit
    #(
        .NB_REG          (NB_REG         ),
        .NB_DATA         (NB_BYTE        ),
        .NB_INSTRUCTION  (NB_INSTRUCTION ),
        .IMEM_ADDR_WIDTH (IMEM_ADDR_WIDTH)
    )
        u_debug_unit
        (
            .o_cpu_en     (debug_unit_cpu_en   ),
            .o_tx_start   (o_uart_tx_start     ),
            .o_rd         (o_uart_rd           ),
            .o_wr         (o_uart_wr           ),
            .o_wdata      (o_uart_wdata        ),
            .o_imem_data  (du_imem_data_to_cpu ),
            .o_imem_waddr (du_imem_waddr_to_cpu),
            .o_imem_wsize (du_imem_wsize_to_cpu),
            .o_imem_wen   (du_imem_wen_to_cpu  ),
            .i_rx_data    (i_uart_rx_data      ),
            .i_rx_done    (i_uart_rx_done      ),
            .i_tx_done    (                    ),
            .i_rst        (i_rst               ),
            .clk          (clk                 )
        );
    
endmodule