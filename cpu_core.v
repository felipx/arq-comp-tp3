//! @title CPU_CORE
//! @file cpu_core.v
//! @author Felipe Montero Bruni
//! @date 07-2024
//! @version 0.1

module cpu_core
#(
    // PC Parameters   
    parameter NB_PC = 32,   //! NB of Program Counter

    // Instruction Memory Parameters
    parameter IMEM_ADDR_WIDTH = 10,
    parameter IMEM_DATA_WIDTH = 32

) (
    // outputs
    input i_rst,
    input clk
);

    //! Internal Signals
    wire [NB_PC - 1 : 0] pc_out_connect;
    wire [NB_PC - 1 : 0] adder_to_mux2to1;
    wire [NB_PC - 1 : 0] mux2to1_to_pc;


    // PC Adder
    adder
    #(
        .NB_ADDER (NB_PC)  //! NB of PC
    )
        u_pc_adder
        (
            .o_sum (adder_to_mux2to1    ),
            .i_a   (pc_out_connect      ),
            .i_b   (32'h4               )   //! PC increments by 4

        );


    // PC's Mux
    mux_2to1
    #(
        .NB_MUX (NB_PC)  //! NB of PC
    )
        u_pc_mux_2to1
        (
            .o_mux (mux2to1_to_pc   ),
            .i_a   (adder_to_mux2to1),
            .i_b   (                ),  //TODO: connect signal
            .i_sel (                )   //TODO: connect signal
        );
    

    // Program Counter
    pc
    #(
        .NB_PC (NB_PC)  //! NB of PC
    )
        u_pc
        (
            .o_pc  (pc_out_connect      ),
            .i_pc  (mux2to1_to_pc       ),
            .i_en  (1'b1                ),  //TODO: check if needed
            .i_rst (i_rst               ),
            .clk   (clk                 )
        );

    // Instruction Memory
    memory
    #(
        .ADDR_WIDTH (IMEM_ADDR_WIDTH),
        .DATA_WIDTH (IMEM_DATA_WIDTH)
    )
        u_instruction_memory
        (
            .o_dout (                                       ),  //! TODO: connect to IF/ID reg
            .i_din  (                                       ),  //! TODO: connection from uart
            .i_addr (pc_out_connect[IMEM_ADDR_WIDTH - 1 : 0]),  //! Truncate the address to fit the memory's address width
            .i_wen  (                                       ),  //! TODO: check where to connect
            .i_ren  (                                       ),  //! TODO: check where to connect
            .i_rst  (i_rst                                  ),
            .clk    (clk                                    ) 
        );
    
endmodule