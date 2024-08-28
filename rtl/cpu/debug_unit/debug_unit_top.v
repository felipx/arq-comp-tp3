//! @title DEBUG UNIT TOP MODULE
//! @file debug_unit_top.v
//! @author Felipe Montero Bruni
//! @date 8-2024
//! @version 0.1

module debug_unit_top 
#(
    parameter NB_PC           = 32,  //! NB of Program Counter
    parameter NB_REG          = 32,
    parameter NB_DMEM_DATA    = 32,
    parameter NB_UART_DATA    = 8 ,
    parameter NB_INSTRUCTION  = 32,  //! Size of instruction memory data
    parameter IMEM_ADDR_WIDTH = 8 ,  //! Instruction Memory address width
    parameter NB_DATA         = 32    //! For Data Memory address width
) (
    // Outputs
    output wire                           o_cpu_en       ,
    output wire                           o_tx_start     ,
    output wire                           o_rd           ,  //! FIFO Rx read enable output
    output wire                           o_wr           ,  //! FIFO Tx write enable output
    output wire [NB_UART_DATA    - 1 : 0] o_wdata        ,  //! UART Tx write data
    output wire [NB_INSTRUCTION  - 1 : 0] o_imem_data    ,
    output wire [IMEM_ADDR_WIDTH - 1 : 0] o_imem_waddr   ,
    output wire                           o_imem_wen     ,
    output wire                           o_regfile_rd   ,
    output wire [4 : 0]                   o_regfile_raddr,
    output wire                           o_dmem_rd      ,
    output wire [1 : 0]                   o_dmem_rsize   ,
    output wire [NB_DATA         - 1 : 0] o_dmem_raddr   ,
    output wire                           o_rst          ,
    
    // Inputs
    input wire [NB_PC          - 1 : 0] i_pc          ,  //! PC input
    input wire [NB_INSTRUCTION - 1 : 0] i_instr       ,
    input wire [NB_REG         - 1 : 0] i_regfile_data,  //! CPU's register file input
    input wire [NB_DMEM_DATA   - 1 : 0] i_dmem_data   ,  //! CPU'd DMEM data input
    input wire [NB_UART_DATA   - 1 : 0] i_rx_data     ,  //! UART Rx data input
    input wire                          i_rx_done     ,
    input wire                          i_tx_done     ,
    input wire                          i_rst         ,
    input wire                          clk            
);

    //! Internal Buffers
    reg                        tx_start;
    reg                        rd      ;
    reg                        wr      ;
    reg [NB_UART_DATA - 1 : 0] wdata   ;

    //! Internal Connections
    wire                        master_load_fw_start     ;
    wire                        master_send_regs_start   ;
    wire                        master_send_dmem_start   ;
    wire                        master_tx_start          ;
    wire                        master_uart_rd           ;
    wire                        master_uart_wr           ;
    wire [NB_UART_DATA - 1 : 0] master_uart_wdata        ;
    wire                        imem_loader_done         ;
    wire                        imem_loader_tx_start     ;
    wire                        imem_loader_uart_rd      ;
    wire                        imem_loader_uart_wr      ;
    wire [NB_UART_DATA - 1 : 0] imem_loader_uart_wdata   ;
    wire                        regfile_reader_done      ;
    wire                        regfile_reader_tx_start  ;
    wire                        regfile_reader_uart_wr   ;
    wire [NB_UART_DATA - 1 : 0] regfile_reader_uart_wdata;
    wire                        dmem_tx_done             ;
    wire                        dmem_tx_uart_rd          ;
    wire                        dmem_tx_uart_wr          ;
    wire                        dmem_tx_uart_start       ;
    wire [NB_UART_DATA - 1 : 0] dmem_tx_uart_wdata       ;

    // Output Logic
    assign o_tx_start = tx_start;
    assign o_rd       = rd      ;
    assign o_wr       = wr      ;
    assign o_wdata    = wdata   ;
    

    //! Debug Unit Master Controller
    du_master
    #(
        .NB_INSTRUCTION (NB_INSTRUCTION),
        .NB_UART_DATA   (NB_UART_DATA  )
    )
        u_du_master
        (
            .o_cpu_en          (o_cpu_en              ),
            .o_load_start      (master_load_fw_start  ),
            .o_send_regs_start (master_send_regs_start),
            .o_send_dmem_start (master_send_dmem_start),
            .o_tx_start        (master_tx_start       ),
            .o_rd              (master_uart_rd        ),
            .o_wr              (master_uart_wr        ),  //check this
            .o_wdata           (master_uart_wdata     ),
            .o_rst             (o_rst                 ),
            .i_loader_done     (imem_loader_done      ),
            .i_send_regs_done  (regfile_reader_done   ),
            .i_send_dmem_done  (dmem_tx_done          ),
            .i_instr           (i_instr               ),
            .i_rx_data         (i_rx_data             ),
            .i_rx_done         (i_rx_done             ),
            .i_rst             (i_rst                 ),
            .clk               (clk                   )
        );
    
    
    //! Debug Unit FW Loader
    du_imem_loader
    #(
        .NB_UART_DATA    (NB_UART_DATA   ),
        .NB_REG          (NB_REG         ),
        .NB_INSTRUCTION  (NB_INSTRUCTION ),
        .IMEM_ADDR_WIDTH (IMEM_ADDR_WIDTH) 
    )
        u_du_imem_loader
        (
            .o_done       (imem_loader_done      ),
            .o_tx_start   (imem_loader_tx_start  ),
            .o_rd         (imem_loader_uart_rd   ),
            .o_wr         (imem_loader_uart_wr   ), //check this
            .o_wdata      (imem_loader_uart_wdata),
            .o_imem_data  (o_imem_data           ),
            .o_imem_waddr (o_imem_waddr          ),
            .o_imem_wen   (o_imem_wen            ),
            .i_start      (master_load_fw_start  ),
            .i_rx_done    (i_rx_done             ),
            .i_rx_data    (i_rx_data             ),
            .i_rst        (i_rst                 ),
            .clk          (clk                   )
        );
    
    
    //! Debug Unit Register File Read/Send Unit
    du_regfile_tx
    #(
        .NB_PC        (NB_PC       ),
        .NB_REG       (NB_REG      ),
        .NB_UART_DATA (NB_UART_DATA)
    )
        u_du_regfile_tx
        (
            .o_done          (regfile_reader_done      ),
            .o_tx_start      (regfile_reader_tx_start  ),
            .o_wr            (regfile_reader_uart_wr   ),
            .o_wdata         (regfile_reader_uart_wdata),
            .o_regfile_rd    (o_regfile_rd             ),
            .o_regfile_raddr (o_regfile_raddr          ),
            .i_start         (master_send_regs_start   ),
            .i_pc            (i_pc                     ),
            .i_regfile_data  (i_regfile_data           ),
            .i_tx_done       (i_tx_done                ),
            .i_rst           (i_rst                    ),
            .clk             (clk                      )
        );
    
    
    //! Debug Unit Data Memory Read/Send Unit
    du_dmem_tx
    #(
        .NB_DATA         (NB_DMEM_DATA   ),   
        .NB_UART_DATA    (NB_UART_DATA   )
    )
        u_du_dmem_tx
        (
            .o_done       (dmem_tx_done          ),
            .o_dmem_rd    (o_dmem_rd             ),
            .o_dmem_rsize (o_dmem_rsize          ),
            .o_dmem_raddr (o_dmem_raddr          ),
            .o_rd         (dmem_tx_uart_rd       ),
            .o_wr         (dmem_tx_uart_wr       ),
            .o_tx_start   (dmem_tx_uart_start    ),
            .o_wdata      (dmem_tx_uart_wdata    ),
            .i_start      (master_send_dmem_start),
            .i_dmem_data  (i_dmem_data           ),
            .i_rx_done    (i_rx_done             ),
            .i_rx_data    (i_rx_data             ),
            .i_tx_done    (i_tx_done             ),
            .i_rst        (i_rst                 ),
            .clk          (clk                   )
        );

    //! Internal Buffers Logic
    always @(posedge clk) begin
        tx_start <= master_tx_start   | imem_loader_tx_start   | regfile_reader_tx_start   | dmem_tx_uart_start;
        rd       <= master_uart_rd    | imem_loader_uart_rd    | dmem_tx_uart_rd                               ;
        wr       <= master_uart_wr    | imem_loader_uart_wr    | regfile_reader_uart_wr    | dmem_tx_uart_wr   ;
        wdata    <= master_uart_wdata | imem_loader_uart_wdata | regfile_reader_uart_wdata | dmem_tx_uart_wdata;
    end
    
endmodule