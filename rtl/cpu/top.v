module top
#(
    parameter NB_PC              = 32,  //! NB of Program Counter
    parameter NB_INSTRUCTION     = 32,  //! Size of each memory location
    parameter NB_DATA            = 32,  //! Size of Integer Base registers
    parameter IMEM_ADDR_WIDTH    = 5,   //! Instruction Memory address width
    parameter DMEM_ADDR_WIDTH    = 5 ,  //! Data Memory address width
    parameter NB_CTRL            = 11   //! NB of control    
) (
    input i_rst,
    input clk
);

    // CPU Core
    cpu_core
    #(
        .NB_ADDER (NB_PC)
    )
        u_cpu
        (
            i_imem_data  (),
            i_imem_waddr (),
            i_imem_wen   (),
            i_mem_wsize  (),
            i_en         (),
            i_rst        (i_rst),
            clk          (clk  )
        );
    
endmodule