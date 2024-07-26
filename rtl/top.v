module top
(
    input i_rst,
    input clk
);

    // CPU Subsystem
    cpu_subsystem
    #()
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