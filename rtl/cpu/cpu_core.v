//! @title CPU_CORE
//! @file cpu_core.v
//! @author Felipe Montero Bruni
//! @date 07-2024
//! @version 0.1

module cpu_core
#(
    parameter NB_PC              = 32,  //! NB of Program Counter
    parameter NB_INSTRUCTION     = 32,  //! Size of each memory location
    parameter NB_DATA            = 32,  //! Size of Integer Base registers
    parameter IMEM_ADDR_WIDTH    = 5,  //! Instruction Memory address width
    parameter DMEM_ADDR_WIDTH    = 5 ,  //! Data Memory address width
    parameter NB_CTRL            = 11   //! NB of control
    
) (
    // Outputs

    // Inputs
    input [NB_DATA         - 1 : 0] i_imem_data ,  //! Instruction memory input
    input [IMEM_ADDR_WIDTH - 1 : 0] i_imem_waddr,  //! Instrunction memory write address
    input                           i_imem_wen  ,  //! Instruction memory write enable
    input                           i_mem_wsize ,  //! Instruction memory write size
    input                           i_rst       ,
    input                           clk         
);
    
    //! Internal Signals
    // PC output connections
    wire [NB_PC - 1 : 0] pc_out_connect;                 //! Program Counter output connection
    
    // PC's adder output connections
    wire [NB_PC - 1 : 0] pc_adder_out_connect;           //! Program Counter's adder to mux connection
    
    // PC's mux output connections
    wire [NB_PC - 1 : 0] mux2to1_to_pc;                  //! Mux to Program Counter connection
    
    // Instruction Memory output connections
    wire [NB_INSTRUCTION - 1 : 0] imem_to_if_id_reg;               //! Instruction memory to IF/ID reg connection
    
    // IF/ID Register output connections
    wire [NB_INSTRUCTION - 1 : 0] if_id_instruction_out_connect;   //! Instruction from IF/ID reg connection
    wire [NB_PC          - 1 : 0] if_id_pc_out_connect         ;   //! PC from IF/ID reg connection
    wire [NB_PC          - 1 : 0] if_id_pc_next_out_connect    ;   //! PC+4 from IF/ID reg connection
    
    // Base Integer Register File output connections
    wire [NB_INSTRUCTION - 1 : 0] int_regfile_data1_to_id_ex_reg;  //! Integer Refile data1 to ID/EX pipelinereg
    wire [NB_INSTRUCTION - 1 : 0] int_regfile_data2_to_id_ex_reg;  //! Integer Refile data2 to ID/EX pipelinereg
    
    // Immediate Generator output connections
    wire [NB_DATA - 1 : 0] imm_out_connect;                 //! Immediate Generator output connection
    
    // Control Unit output connections
    wire [NB_CTRL - 1 : 0] ctrl_unit_out_connect;

    // Hazard Detection Unit output connections
    wire hdu_pcWrite_to_pc       ;
    wire hdu_IfIdWrite_to_IfIdReg;
    wire hdu_to_nop_mux          ;

    // Hazard Detection Unit Mux (NOP insertion Mux) connections
    wire [NB_CTRL        - 1 : 0] id_nop_insert_mux_out_connect;

    // ID/EX Register output connections
    wire [NB_DATA        - 1 : 0] id_ex_ctrl_out_connect       ;  //! Ctrl signals from ID/EX reg connection
    wire [NB_PC          - 1 : 0] id_ex_pc_out_connect         ;  //! PC from ID/EX reg connection
    wire [NB_PC          - 1 : 0] id_ex_pc_next_out_connect    ;  //! PC+4 from ID/EX reg connection
    wire [NB_DATA        - 1 : 0] id_ex_imm_out_connect        ;  //! ID/EX Immediate output connection
    wire [NB_DATA        - 1 : 0] id_ex_rs1_data_out_connect   ;  //! ID/EX rs1 reg output connection
    wire [NB_DATA        - 1 : 0] id_ex_rs2_data_out_connect   ;  //! ID/EX rs1 reg output connection
    wire [NB_INSTRUCTION - 1 : 0] id_ex_instruction_out_connect;  //! Instruction from ID/EX reg connection

    // Branch Control Unit output connections
    wire [1 : 0] branch_ctrl_unit_pc_out_connect;
    wire         branch_ctrl_unit_flush_out_connect;

    // Branch target Address Calculator Adder output connections
    wire [NB_DATA - 1 : 0] adder_addr_out_connect;

    // EX Forwarding Unit output connections
    wire [1 : 0] fowrward_unit_a_out_connect;
    wire [1 : 0] fowrward_unit_b_out_connect;

    // Forwarding Mux A output connections
    wire [NB_DATA - 1 : 0] forwarding_mux_a_out_connect;

    // Forwarding Mux A output connections
    wire [NB_DATA - 1 : 0] forwarding_mux_b_out_connect;

    // ALU input Mux output connections
    wire [NB_DATA - 1 : 0] alu_input_mux_out_connect;

    // ALU output connections
    wire [NB_DATA - 1 : 0] alu_result_connect;
    wire                   alu_zero_connect  ;

    // ALU Control Unit output connections
    wire [4 : 0] alu_op_out_connect;

    // EX/MEM Register output connections
    wire [NB_DATA        - 1 : 0] ex_mem_ctrl_out_connect       ;  //! Ctrl signals from EX/MEM reg connection
    wire [NB_DATA        - 1 : 0] ex_mem_alu_out_connect        ;  //! ALU result from EX/MEM reg connection
    wire [NB_DATA        - 1 : 0] ex_mem_data_out_connect       ;
    wire [NB_INSTRUCTION - 1 : 0] ex_mem_instruction_out_connect;  //! Instruction from EX/MEM reg connection

    // Data Memory output conenctions
    wire [NB_DATA - 1 : 0] data_memory_out_connect;

    // MEM/WB Register output connections
    wire [NB_DATA        - 1 : 0] mem_wb_ctrl_out_connect       ;  //! Ctrl signals from MEM/WB reg connection
    wire [NB_DATA        - 1 : 0] mem_wb_data_out_connect       ;  //! Data memory output from MEM/WB reg connection
    wire [NB_DATA        - 1 : 0] mem_wb_alu_out_connect        ;  //! ALU result output from MEM/WB reg connection
    wire [NB_INSTRUCTION - 1 : 0] mem_wb_instruction_out_connect;  //! Instruction from MEM/WB reg connection




    // WB Mux output connections
    wire [NB_DATA        - 1 : 0] wb_mux_out_connect;



    //
    // Instruction Fetch Stage Modules Start
    //
    
    // PC's Adder
    adder
    #(
        .NB_ADDER (NB_PC)
    )
        u_pc_adder
        (
            .o_sum (pc_adder_out_connect),
            .i_a   (pc_out_connect      ),
            .i_b   (32'h4               )   //! PC increments by 4
        );
    
    // PC's Mux
    mux_3to1
    #(
        .NB_MUX (NB_PC)
    )
        u_pc_mux_3to1
        (
            .o_mux (mux2to1_to_pc                  ),
            .i_a   (pc_adder_out_connect           ),  // PC+4
            .i_b   (adder_addr_out_connect         ),  // JAL and Branches
            .i_c   (alu_result_connect             ),  // JALR
            .i_sel (branch_ctrl_unit_pc_out_connect)
        );
    
    // Program Counter
    pc
    #(
        .NB_PC (NB_PC)
    )
        u_pc
        (
            .o_pc  (pc_out_connect   ),
            .i_pc  (mux2to1_to_pc    ),
            .i_en  (hdu_pcWrite_to_pc),
            .i_rst (i_rst            ),
            .clk   (clk              )
        );
    
    // Instruction Memory
    memory
    #(
        .ADDR_WIDTH (IMEM_ADDR_WIDTH)
    )
        u_instruction_memory
        (
            .o_dout  (imem_to_if_id_reg                      ),
            .i_din   (i_imem_data                            ),
            .i_waddr (i_imem_waddr                           ),
            .i_raddr (pc_out_connect[IMEM_ADDR_WIDTH - 1 : 0]),  // Truncate the address to fit the memory's address width
            .i_wsize (i_mem_wsize                            ),
            .i_wen   (i_mem_wen                              ),
            .i_ren   (~i_mem_wen                             ),  // TODO: Check if OK
            .i_rst   (i_rst                                  ),
            .clk     (clk                                    ) 
        );
    
    // IF/ID Pipeline Register
    if_id_reg
    #(
        .NB_INSTR (NB_INSTRUCTION),
        .NB_PC    (NB_PC          )
    )
        u_if_id_reg
        (
            .o_instr   (if_id_instruction_out_connect     ),
            .o_pc      (if_id_pc_out_connect              ),
            .o_pc_next (if_id_pc_next_out_connect         ),
            .i_instr   (imem_to_if_id_reg                 ),  
            .i_pc      (pc_out_connect                    ),
            .i_pc_next (pc_adder_out_connect              ),
            .i_flush   (branch_ctrl_unit_flush_out_connect),   
            .i_en      (hdu_IfIdWrite_to_IfIdReg          ),  
            .i_rst     (i_rst                             ),  
            .clk       (clk                               ) 
        );
    
    //
    // Instruction Decode/Register File Read Stage Modules
    //
    
    // Integer Register File
    regfile
    #(
        .DATA_WIDTH (NB_DATA)
    )
        u_integer_regfile
        (
            .o_dout1 (int_regfile_data1_to_id_ex_reg        ),
            .o_dout2 (int_regfile_data2_to_id_ex_reg        ),
            .i_addr1 (if_id_instruction_out_connect[19 : 15]),
            .i_addr2 (if_id_instruction_out_connect[24 : 20]),
            .i_waddr (mem_wb_instruction_out_connect[11 : 7]),
            .i_wdata (wb_mux_out_connect                    ),
            .i_wen   (mem_wb_ctrl_out_connect[0]            ),
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
        .NB_CTRL (NB_CTRL)
    )
        u_base_integer_ctrl_unit
        (
            .o_ctrl   (ctrl_unit_out_connect                 ),
            .i_opcode (if_id_instruction_out_connect[6  :  0]),
            .i_func3  (if_id_instruction_out_connect[14 : 12])
        );
    
    // Hazard Detection Unit
    hazard_detection_unit
    #()
        u_hazard_detection_unit
        (
            .o_pc_write       (hdu_pcWrite_to_pc                     ),
            .o_if_id_write    (hdu_IfIdWrite_to_IfIdReg              ),
            .o_control_mux    (hdu_to_nop_mux                        ),
            .i_id_ex_mem_read (id_ex_ctrl_out_connect[1]             ),
            .i_id_ex_rd       (id_ex_instruction_out_connect[11 :  7]),
            .i_if_id_rs1      (if_id_instruction_out_connect[19 : 15]),
            .i_if_id_rs2      (if_id_instruction_out_connect[24 : 20])
        );
    
    // NOP Instruction Mux
    mux_4to1
    #(
        .NB_MUX (NB_CTRL)
    )
        u_nop_insertion_mux
        (
            o_data  (id_nop_insert_mux_out_connect                       ),
            i_data0 (ctrl_unit_out_connect                               ),
            i_data1 ({NB_CTRL{1'b0}}                                     ),
            i_data2 ({NB_CTRL{1'b0}}                                     ),
            i_data3 ({NB_CTRL{1'b0}}                                     ),
            i_sel   ({hdu_to_nop_mux, branch_ctrl_unit_flush_out_connect}) 
        );
    
    // ID/EX Pipeline Register
    id_ex_reg
    #(
        .DATA_WIDTH (NB_DATA)
    )
        u_id_ex_reg
        (
            .o_ctrl     (id_ex_ctrl_out_connect                     ),
            .o_pc       (id_ex_pc_out_connect                       ),
            .o_pc_next  (id_ex_pc_next_out_connect                  ),
            .o_rs1_data (id_ex_rs1_data_out_connect                 ),
            .o_rs2_data (id_ex_rs2_data_out_connect                 ),
            .o_imm      (id_ex_imm_out_connect                      ),
            .o_instr    (id_ex_instruction_out_connect              ),
            .i_ctrl     ({{21{1'b0}}, id_nop_insert_mux_out_connect}),
            .i_pc       (if_id_pc_out_connect                       ),
            .i_pc_next  (if_id_pc_next_out_connect                  ),
            .i_rs1_data (int_regfile_data1_to_id_ex_reg             ),
            .i_rs2_data (int_regfile_data2_to_id_ex_reg             ),
            .i_imm      (imm_out_connect                            ),
            .i_instr    (if_id_instruction_out_connect              ),
            .i_en       (1'b1                                       ),  //TODO: check if OK
            .i_rst      (i_rst                                      ),
            .clk        (clk                                        ) 
        );
    
    //
    // Execution/Address Calculation Stage Modules
    //

    branch_ctrl_unit
    #(
        .NB_DATA (NB_DATA)
    )
        u_branch_ctrl_unit
        (
            .o_pcSrc      (branch_ctrl_unit_pc_out_connect       ),
            .o_flush      (branch_ctrl_unit_flush_out_connect    ),
            .i_alu_result (alu_result_connect                    ),
            .i_alu_zero   (alu_zero_connect                      ),
            .i_opcode     (id_ex_instruction_out_connect[6  :  0]),
            .i_func3      (id_ex_instruction_out_connect[14 : 12])
        );
    
    // Forwarding Mux 1
    mux_3to1
    #(
        .NB_MUX (NB_DATA)
    )
        u_forwarding_mux_1
        (
            .o_data  (forwarding_mux_a_out_connect), 
            .i_data0 (id_ex_rs1_data_out_connect  ),
            .i_data1 (wb_mux_out_connect          ),
            .i_data2 (ex_mem_alu_out_connect      ),
            .i_sel   (fowrward_unit_a_out_connect ) 
        );
    
    // Forwarding Mux 2
    mux_3to1
    #(
        .NB_MUX (NB_DATA)
    )
        u_forwarding_mux_2
        (
            .o_data  (forwarding_mux_b_out_connect), 
            .i_data0 (id_ex_rs2_data_out_connect  ),
            .i_data1 (wb_mux_out_connect          ),
            .i_data2 (ex_mem_alu_out_connect      ),
            .i_sel   (fowrward_unit_b_out_connect ) 
        );
    
    // ALU Input Mux
    mux_2to1
    #(
        .NB_MUX (NB_DATA)
    )
        u_alu_input_mux
        (
            o_mux (alu_input_mux_out_connect   ),
            i_a   (forwarding_mux_b_out_connect),
            i_b   (id_ex_imm_out_connect       ),
            i_sel (id_ex_ctrl_out_connect[3]   ) 
        );
    
    // Branch target Address Calculator Adder
    adder
    #(
        .NB_ADDER (NB_PC)
    )
        u_branch_target_adder
        (
            .o_sum (adder_addr_out_connect),
            .i_a   (id_ex_pc_out_connect  ),
            .i_b   (id_ex_imm_out_connect )
        );
    
    // ALU
    alu
    #(
        .NB_DATA (NB_DATA)
    )
        u_alu
        (
            .o_result      (alu_result_connect          ),
            .o_zero        (alu_zero_connect            ),
            .i_data1       (forwarding_mux_a_out_connect),
            .i_data2       (alu_input_mux_out_connect   ),
            .i_alu_op      (alu_op_out_connect          ) 
        );
    
    // ALU Control Unit
    alu_ctrl_unit
    #()
        u_alu_ctrl_unit
        (
            .o_alu_op (alu_op_out_connect                    ),     
            .i_alu_op (id_ex_ctrl_out_connect[8 : 7]         ),
            .i_funct7 (id_ex_instruction_out_connect[31 : 25]),
            .i_funct3 (id_ex_instruction_out_connect[14 : 12])
        );
    
    // EX Forwarding Unit
    ex_forwarding_unit
    #()
        u_ex_forwarding_unit
        (
            .o_forward_a    (fowrward_unit_a_out_connect           ),   
            .o_forward_b    (fowrward_unit_b_out_connect           ),              
            .i_ex_rs1       (id_ex_instruction_out_connect[19 : 15]),
            .i_ex_rs2       (id_ex_instruction_out_connect[24 : 20]),
            .i_mem_rd       (ex_mem_instruction_out_connect[11 : 7]),
            .i_wb_rd        (mem_wb_instruction_out_connect[11 : 7]),
            .i_mem_RegWrite (ex_mem_ctrl_out_connect[0]            ),
            .i_wb_RegWrite  (mem_wb_ctrl_out_connect[0]            ) 
        );
    
    // EX/MEM Pipeline Register
    ex_mem_reg
    #(
        .DATA_WIDTH (NB_DATA)
    )
        u_ex_mem_reg
        (
            .o_ctrl    (ex_mem_ctrl_out_connect                                      ),
            .o_pc_addr (),
            .o_pc_next (                                    ),
            .o_alu     (ex_mem_alu_out_connect                                       ),
            .o_data2   (ex_mem_data_out_connect                                      ),
            .o_instr   (ex_mem_instruction_out_connect                               ),
            .i_ctrl    ({{20{1'b0}}, alu_zero_connect, id_ex_ctrl_out_connect[8 : 0]}),
            .i_pc_addr (adder_addr_out_connect                                       ),
            .i_pc_next (id_ex_pc_next_out_connect                                    ),
            .i_alu     (alu_result_connect                                           ),
            .i_data2   (forwarding_mux_b_out_connect                                 ),
            .i_instr   (id_ex_instruction_out_connect                                ),
            .i_en      (1'b1                                                         ), //TODO: Check if OK
            .i_rst     (i_rst                                                        ),
            .clk       (clk                                                          ) 
        );
    
    //
    // Memory Access Stage Modules
    //
    
    // Data Memory
    memory
    #(
        .ADDR_WIDTH (DMEM_ADDR_WIDTH)
    )
        u_data_memory
        (
            .o_dout  (data_memory_out_connect   ),
            .i_din   (ex_mem_data_out_connect   ),
            .i_waddr (ex_mem_alu_out_connect    ),
            .i_raddr (ex_mem_alu_out_connect    ),
            .i_wsize (),
            .i_wen   (ex_mem_ctrl_out_connect[2]),
            .i_ren   (ex_mem_ctrl_out_connect[1]),
            .i_rst   (i_rst                     ),
            .clk     (clk                       ) 
        );    
    
    // MEM Forwarding Unit
    mem_forwarding_unit
    #()
        u_mem_forwarding_unit
        (
            .o_forward_b   (),  
            .i_mem_rs2     (),
            .i_wb_rd       (),
            .i_wb_RegWrite () 
        );
    
    // MEM/WB Pipeline Register
    mem_wb_reg
    #(

    )
        u_mem_wb_reg
        (
            .o_ctrl  (mem_wb_ctrl_out_connect       ),
            .o_data  (mem_wb_data_out_connect       ),
            .o_alu   (mem_wb_alu_out_connect        ),
            .o_instr (mem_wb_instruction_out_connect),
            .i_ctrl  (ex_mem_ctrl_out_connect       ),
            .i_data  (data_memory_out_connect       ),
            .i_alu   (ex_mem_alu_out_connect        ),
            .i_instr (ex_mem_instruction_out_connect),
            .i_en    (1'b1                          ), //TODO: Check if OK
            .i_rst   (i_rst                         ),
            .clk     (clk                           ) 
        );
    
    //
    // Write Back Stage Modules
    //
    
    // WB Mux
    mux_2to1
    #(
        .NB_MUX (NB_DATA)
    )
        u_wb_mux
        (
            .o_mux (wb_mux_out_connect        ),
            .i_a   (mem_wb_alu_out_connect    ),
            .i_b   (mem_wb_data_out_connect   ),
            .i_sel (mem_wb_ctrl_out_connect[4]) 
        );


endmodule