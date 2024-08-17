//! @title CPU SUBSYTEM
//! @file cpu_subsystem.v
//! @author Felipe Montero Bruni
//! @date 7-2024
//! @version 0.1

module cpu_subsystem
#(
    parameter NB_PC              = 32,  //! NB of Program Counter
    parameter NB_INSTRUCTION     = 32,  //! Size of each memory location
    parameter NB_DATA            = 32,  //! SIze of DMEM data
    parameter NB_REG             = 32,  //! Size of Integer Base registers
    parameter IMEM_ADDR_WIDTH    = 10,  //! Instruction Memory address width
    parameter DMEM_ADDR_WIDTH    = 10 ,  //! Data Memory address width
    parameter NB_UART_DATA       = 8  
) (
    // Outputs
    output wire                        o_uart_tx_start,
    output wire                        o_uart_rd      ,
    output wire                        o_uart_wr      ,
    output wire [NB_UART_DATA - 1 : 0] o_uart_wdata   ,

    // Inputs
    input wire [NB_UART_DATA - 1 : 0] i_uart_rx_data,
    input wire                        i_uart_rx_done,
    input wire                        i_uart_tx_done,
    input wire                        i_en          ,
    input wire                        i_rst         ,
    input wire                        clk            
);

    //! Localparameters
    localparam NB_BYTE         = 8;
    localparam NB_REGFILE_ADDR = 5;

    //! Internal Buffers
    reg [NB_PC           - 1 : 0] pc_to_du           ;
    reg [NB_INSTRUCTION  - 1 : 0] cpu_instr_to_du    ;
    reg [NB_REG          - 1 : 0] cpu_reg_to_du      ;
    reg [NB_DATA         - 1 : 0] cpu_dmem_data_to_du;

    reg                           debug_unit_cpu_en     ;
    reg [NB_INSTRUCTION  - 1 : 0] du_imem_data_to_cpu   ;
    reg [IMEM_ADDR_WIDTH - 1 : 0] du_imem_waddr_to_cpu  ;
    reg [1 : 0]                   du_imem_size_to_cpu   ;
    reg                           du_imem_wen_to_cpu    ;
    reg                           du_regfile_rd_to_cpu  ;
    reg [NB_REGFILE_ADDR - 1 : 0] du_regfile_addr_to_cpu;
    reg [DMEM_ADDR_WIDTH - 1 : 0] du_dmem_raddr_to_cpu  ;
    reg [1 : 0]                   du_dmem_rsize_to_cpu  ;
    reg                           du_dmem_ren_to_cpu    ;
    reg                           du_rst                ;

    reg                           uart_tx_start;
    reg                           uart_rd      ;
    reg                           uart_wr      ;
    reg [NB_UART_DATA - 1 : 0]    uart_wdata   ;

    reg [NB_UART_DATA - 1 : 0]    uart_rx_data;
    reg                           uart_rx_done;
    reg                           uart_tx_done;

    //! Connections
    // CPU to DU
    wire [NB_PC           - 1 : 0] pc_to_du_out           ;
    wire [NB_INSTRUCTION  - 1 : 0] cpu_instr_to_du_out    ;
    wire [NB_REG          - 1 : 0] cpu_reg_to_du_out      ;
    wire [NB_DATA         - 1 : 0] cpu_dmem_data_to_du_out;

    // DU to CPU
    wire                           debug_unit_cpu_en_out     ;
    wire [NB_INSTRUCTION  - 1 : 0] du_imem_data_to_cpu_out   ;
    wire [IMEM_ADDR_WIDTH - 1 : 0] du_imem_waddr_to_cpu_out  ;
    wire [1 : 0]                   du_imem_size_to_cpu_out   ;
    wire                           du_imem_wen_to_cpu_out    ;
    wire                           du_regfile_rd_to_cpu_out  ;
    wire [NB_REGFILE_ADDR - 1 : 0] du_regfile_addr_to_cpu_out;
    wire [NB_DATA         - 1 : 0] du_dmem_raddr_to_cpu_out  ;
    wire [1 : 0]                   du_dmem_rsize_to_cpu_out  ;
    wire                           du_dmem_ren_to_cpu_out    ;
    wire                           du_rst_out                ;

    wire                        uart_tx_start_out;
    wire                        uart_rd_out      ;
    wire                        uart_wr_out      ;
    wire [NB_UART_DATA - 1 : 0] uart_wdata_out   ;

    //! Output Logic
    assign o_uart_tx_start = uart_tx_start;
    assign o_uart_rd       = uart_rd      ;
    assign o_uart_wr       = uart_wr      ;
    assign o_uart_wdata    = uart_wdata   ;
    
    
    //! CPU Core
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
            .o_pc           (pc_to_du_out            ),
            .o_instr        (cpu_instr_to_du_out     ),
            .o_regfile_data (cpu_reg_to_du_out       ),
            .o_dmem_data    (cpu_dmem_data_to_du_out ),
            .i_du_rgfile_rd (du_regfile_rd_to_cpu    ),
            .i_regfile_addr (du_regfile_addr_to_cpu  ),
            .i_imem_data    (du_imem_data_to_cpu     ),
            .i_imem_waddr   (du_imem_waddr_to_cpu    ),
            .i_imem_size    (du_imem_size_to_cpu     ),
            .i_imem_wen     (du_imem_wen_to_cpu      ),
            .i_dmem_raddr   (du_dmem_raddr_to_cpu    ),
            .i_dmem_rsize   (du_dmem_rsize_to_cpu    ),
            .i_dmem_ren     (du_dmem_ren_to_cpu      ),
            .i_en           (i_en & debug_unit_cpu_en),
            .i_du_rst       (du_rst                  ),
            .i_rst          (i_rst                   ),
            .clk            (clk                     )
        );
    
    //! Debug Unit
    debug_unit_top
    #(
        .NB_PC           (NB_PC          ),
        .NB_REG          (NB_REG         ),
        .NB_DMEM_DATA    (NB_DATA        ),
        .NB_UART_DATA    (NB_BYTE        ),
        .NB_INSTRUCTION  (NB_INSTRUCTION ),
        .IMEM_ADDR_WIDTH (IMEM_ADDR_WIDTH),
        .NB_DATA         (NB_DATA        )
    )
        u_debug_unit
        (
            .o_cpu_en       (debug_unit_cpu_en_out     ),
            .o_tx_start     (uart_tx_start_out         ),
            .o_rd           (uart_rd_out               ),
            .o_wr           (uart_wr_out               ),
            .o_wdata        (uart_wdata_out            ),
            .o_imem_data    (du_imem_data_to_cpu_out   ),
            .o_imem_waddr   (du_imem_waddr_to_cpu_out  ),
            .o_imem_size    (du_imem_size_to_cpu_out   ),
            .o_imem_wen     (du_imem_wen_to_cpu_out    ),
            .o_regfile_rd   (du_regfile_rd_to_cpu_out  ),
            .o_regfile_raddr(du_regfile_addr_to_cpu_out),
            .o_dmem_rd      (du_dmem_ren_to_cpu_out    ),
            .o_dmem_rsize   (du_dmem_rsize_to_cpu_out  ),
            .o_dmem_raddr   (du_dmem_raddr_to_cpu_out  ),
            .o_rst          (du_rst_out                ),
            .i_pc           (pc_to_du                  ),
            .i_instr        (cpu_instr_to_du           ),
            .i_regfile_data (cpu_reg_to_du             ),
            .i_dmem_data    (cpu_dmem_data_to_du       ),
            .i_rx_data      (uart_rx_data              ),
            .i_rx_done      (uart_rx_done              ),
            .i_tx_done      (uart_tx_done              ),
            .i_rst          (i_rst                     ),
            .clk            (clk                       )
        );

    //! Debug Unit buffers Logic
    always @(posedge clk) begin
        pc_to_du               <= pc_to_du_out                                     ;
        cpu_instr_to_du        <= cpu_instr_to_du_out                              ;
        cpu_reg_to_du          <= cpu_reg_to_du_out                                ;
        cpu_dmem_data_to_du    <= cpu_dmem_data_to_du_out                          ;
        debug_unit_cpu_en      <= debug_unit_cpu_en_out                            ;
        du_imem_data_to_cpu    <= du_imem_data_to_cpu_out                          ;
        du_imem_waddr_to_cpu   <= du_imem_waddr_to_cpu_out                         ;
        du_imem_size_to_cpu    <= du_imem_size_to_cpu_out                          ;
        du_imem_wen_to_cpu     <= du_imem_wen_to_cpu_out                           ;
        du_regfile_rd_to_cpu   <= du_regfile_rd_to_cpu_out                         ;
        du_regfile_addr_to_cpu <= du_regfile_addr_to_cpu_out                       ;
        du_dmem_raddr_to_cpu   <= du_dmem_raddr_to_cpu_out[DMEM_ADDR_WIDTH - 1 : 0];
        du_dmem_rsize_to_cpu   <= du_dmem_rsize_to_cpu_out                         ;
        du_dmem_ren_to_cpu     <= du_dmem_ren_to_cpu_out                           ;
        du_rst                 <= du_rst_out                                       ;
        uart_tx_start          <= uart_tx_start_out                                ;
        uart_rd                <= uart_rd_out                                      ;
        uart_wr                <= uart_wr_out                                      ;
        uart_wdata             <= uart_wdata_out                                   ;
        uart_rx_data           <= i_uart_rx_data                                   ;
        uart_rx_done           <= i_uart_rx_done                                   ;
        uart_tx_done           <= i_uart_tx_done                                   ; 
    end
    
endmodule