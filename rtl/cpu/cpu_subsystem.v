module cpu_subsystem
(
    input i_imem_data ,
    input i_imem_waddr,
    input i_imem_wen  ,
    input i_mem_wsize ,
    input i_en        ,
    input i_rst       ,
    input clk          
);
    localparam NB_PC              = 32,  //! NB of Program Counter
    localparam NB_INSTRUCTION     = 32,  //! Size of each memory location
    localparam NB_DATA            = 32,  //! Size of Integer Base registers
    localparam IMEM_ADDR_WIDTH    = 5,   //! Instruction Memory address width
    localparam DMEM_ADDR_WIDTH    = 5 ,  //! Data Memory address width  

    // CPU Core
    cpu_core
    #(
        .NB_PC           (NB_PC          ),
        .NB_INSTRUCTION  (NB_INSTRUCTION ),
        .NB_DATA         (NB_DATA        ),
        .IMEM_ADDR_WIDTH (IMEM_ADDR_WIDTH),
        .DMEM_ADDR_WIDTH (DMEM_ADDR_WIDTH)
    )
        u_cpu
        (
            i_imem_data  (i_imem_data ),
            i_imem_waddr (i_imem_waddr),
            i_imem_wen   (i_imem_wen  ),
            i_mem_wsize  (i_mem_wsize ),
            i_en         (i_en        ),
            i_rst        (i_rst       ),
            clk          (clk         )
        );
    
endmodule