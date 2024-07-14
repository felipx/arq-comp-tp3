//! @title CPU_CORE
//! @file cpu_core.v
//! @author Felipe Montero Bruni
//! @date 07-2024
//! @version 0.1

module cpu_core
#(
    // PC Parameters   
    parameter NB_PC = 32,              //! NB of Program Counter
    
    // Instruction Memory Parameters
    parameter IMEM_ADDR_WIDTH = 10,    //! Instruction Memory address width
    parameter IMEM_DATA_WIDTH = 32     //! Size of each memory location
    
) (
    // outputs
    input i_rst,
    input clk
);
    
    //! Internal Signals
    wire [NB_PC           - 1 : 0] pc_out_connect   ;  //! Program Counter output connection
    wire [NB_PC           - 1 : 0] adder_to_mux2to1 ;  //! Program Counter's adder to mux connection
    wire [NB_PC           - 1 : 0] mux2to1_to_pc    ;  //! Mux to Program Counter connection
    wire [IMEM_DATA_WIDTH - 1 : 0] imem_to_if_id_reg;  //! Instruction memory to IF/ID reg connection
    
    
    // PC's Adder
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
            .o_dout (imem_to_if_id_reg                      ),
            .i_din  (                                       ),  //! TODO: connection from uart
            .i_addr (pc_out_connect[IMEM_ADDR_WIDTH - 1 : 0]),  //! Truncate the address to fit the memory's address width
            .i_wen  (                                       ),  //! TODO: check where to connect
            .i_ren  (                                       ),  //! TODO: check where to connect
            .i_rst  (i_rst                                  ),
            .clk    (clk                                    ) 
        );
    
    // IF/ID Pipeline Register
    if_id_reg
    #(
        .NB_INSTR (IMEM_DATA_WIDTH),
        .NB_PC    (NB_PC          )
    )
        u_if_id_reg
        (
            .o_instr (                 ),  //! TODO
            .o_pc    (                 ),  //! TODO
            .i_instr (imem_to_if_id_reg),  
            .i_pc    (pc_out_connect   ),   
            .i_en    (1'b1             ),  //! TODO: Check if OK  
            .i_rst   (i_rst            ),  
            .clk     (clk              ) 
        );

    // Integer Register File
    regfile
    #(
        .ADDR_WIDTH (),
        .DATA_WIDTH ()
    )
        u_integer_regfile
        (
            .o_dout1 (),
            .o_dout2 (),
            .i_addr1 (),
            .i_addr2 (),
            .i_waddr (),
            .i_wdata (),
            .i_wen   (),
            .i_rst   (),
            .clk     () 
        )
endmodule