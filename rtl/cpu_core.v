//! @title CPU_CORE
//! @file cpu_core.v
//! @author Felipe Montero Bruni
//! @date 07-2024
//! @version 0.1

module cpu_core
#(
    parameter NB_PC              = 32,  //! NB of Program Counter
    parameter IMEM_ADDR_WIDTH    = 10,  //! Instruction Memory address width
    parameter NB_INSTRUCTION     = 32,  //! Size of each memory location
    parameter NB_DATA_REG        = 32,  //! Size of Integer Base registers
    parameter REGFILE_ADDR_WIDTH = 5 ,  //! Base Integer Register File address width 
    parameter NB_CTRL            = 9 ,  //! NB of control
    parameter NB_OPCODE          = 7 ,  //! NB of opcode field
    parameter ID_EX_ADDR_WIDTH   = 3    //! NB of ID/EX address depth
    
) (
    // Inputs
    input i_rst,
    input clk
);
    
    //! Internal Signals
    // PC output connections
    wire [NB_PC           - 1 : 0] pc_out_connect;                 //! Program Counter output connection
    
    // PC's adder output connections
    wire [NB_PC           - 1 : 0] adder_to_mux2to1;               //! Program Counter's adder to mux connection
    
    // PC's mux output connections
    wire [NB_PC           - 1 : 0] mux2to1_to_pc;                  //! Mux to Program Counter connection
    
    // Instruction Memory output connections
    wire [NB_INSTRUCTION - 1 : 0] imem_to_if_id_reg;               //! Instruction memory to IF/ID reg connection
    
    // IF/ID Register output connections
    wire [NB_INSTRUCTION - 1 : 0] if_id_instruction_out_connect;   //! Instruction from IF/ID reg connection
    wire [NB_PC          - 1 : 0] if_id_pc_out_connect         ;   //! PC from IF/ID reg connection
    
    // Base Integer Register File output connections
    wire [NB_INSTRUCTION - 1 : 0] int_regfile_data1_to_id_ex_reg;  //! Integer Refile data1 to ID/EX pipelinereg
    wire [NB_INSTRUCTION - 1 : 0] int_regfile_data2_to_id_ex_reg;  //! Integer Refile data2 to ID/EX pipelinereg
    
    // Immediate Generator output connections
    wire [NB_DATA_REG - 1 : 0] imm_out_connect;
    
    // Control Unit output connections
    wire [NB_CTRL - 1 : 0] ctrl_unit_out_connect;
    
    
    // PC's Adder
    adder
    #(
        .NB_ADDER (NB_PC)
    )
        u_pc_adder
        (
            .o_sum (adder_to_mux2to1),
            .i_a   (pc_out_connect  ),
            .i_b   (32'h4           )   //! PC increments by 4

        );
    
    // PC's Mux
    mux_2to1
    #(
        .NB_MUX (NB_PC)
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
        .NB_PC (NB_PC)
    )
        u_pc
        (
            .o_pc  (pc_out_connect),
            .i_pc  (mux2to1_to_pc ),
            .i_en  (1'b1          ),  //TODO: check if needed
            .i_rst (i_rst         ),
            .clk   (clk           )
        );
    
    // Instruction Memory
    memory
    #(
        .ADDR_WIDTH (IMEM_ADDR_WIDTH),
        .DATA_WIDTH (NB_INSTRUCTION)
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
        .NB_INSTR (NB_INSTRUCTION),
        .NB_PC    (NB_PC          )
    )
        u_if_id_reg
        (
            .o_instr (if_id_instruction_out_connect),
            .o_pc    (if_id_pc_out_connect         ),
            .i_instr (imem_to_if_id_reg            ),  
            .i_pc    (pc_out_connect               ),   
            .i_en    (1'b1                         ),  //! TODO: Check if OK  
            .i_rst   (i_rst                        ),  
            .clk     (clk                          ) 
        );
    
    // Integer Register File
    regfile
    #(
        .ADDR_WIDTH (REGFILE_ADDR_WIDTH),
        .DATA_WIDTH (NB_DATA_REG       )
    )
        u_integer_regfile
        (
            .o_dout1 (int_regfile_data1_to_id_ex_reg        ),
            .o_dout2 (int_regfile_data2_to_id_ex_reg        ),
            .i_addr1 (if_id_instruction_out_connect[19 : 15]),
            .i_addr2 (if_id_instruction_out_connect[24 : 20]),
            .i_waddr (                                      ),  //TODO
            .i_wdata (                                      ),  //TODO
            .i_wen   (                                      ),  //TODO
            .i_rst   (i_rst                                 ),
            .clk     (clk                                   ) 
        );
    
    // Immediate Generator
    imm_gen
    #(
        .DATA_WIDTH (NB_INSTRUCTION)
    )
        u_imm_gen
        (
            .o_imm   (imm_out_connect              ),
            .i_instr (if_id_instruction_out_connect) 
        );
    
    // Base Integer Control Unit
    base_integer_ctrl_unit
    #(
        .NB_CTRL   (NB_CTRL  ),
        .NB_OPCODE (NB_OPCODE)
    )
        u_base_integer_ctrl_unit
        (
            .o_ctrl (ctrl_unit_out_connect)
        );
    
    // ID/EX Pipeline Register
    id_ex_reg
    #(
        .DATA_WIDTH (NB_DATA_REG     ),
        .ADDR_WIDTH (ID_EX_ADDR_WIDTH)
    )
        u_id_ex_reg
        (
            .o_ctrl  (                              ),  //TODO
            .o_pc    (                              ),  //TODO
            .o_rs1   (                              ),  //TODO
            .o_rs2   (                              ),  //TODO
            .o_imm   (                              ),  //TODO
            .o_instr (                              ),  //TODO
            .i_ctrl  (                              ),  //TODO
            .i_pc    (if_id_pc_out_connect          ),
            .i_rs1   (int_regfile_data1_to_id_ex_reg),
            .i_rs2   (int_regfile_data2_to_id_ex_reg),
            .i_imm   (imm_out_connect               ),
            .i_instr (if_id_instruction_out_connect ),
            .i_en    (1'b1                          ),  //TODO: check if OK
            .i_rst   (i_rst                         ),
            .clk     (clk                           ) 
        );

endmodule