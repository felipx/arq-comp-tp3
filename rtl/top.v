module top
#(
    parameter NB_PC              = 32,  //! NB of Program Counter
    parameter NB_INSTRUCTION     = 32,  //! Size of each memory location
    parameter NB_DATA            = 32,  //! Size of Integer Base registers
    parameter IMEM_ADDR_WIDTH    = 8 ,  //! Instruction Memory address width
    parameter DMEM_ADDR_WIDTH    = 5    //! Data Memory address width
) (
    input i_rst,
    input clk
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
    
endmodule