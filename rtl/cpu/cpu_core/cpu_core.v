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
    parameter IMEM_ADDR_WIDTH    = 10,  //! Instruction Memory address width
    parameter DMEM_ADDR_WIDTH    = 10   //! Data Memory address width
) (
    // Outputs
    output reg [NB_PC          - 1 : 0] o_pc          ,
    output reg [NB_INSTRUCTION - 1 : 0] o_instr       ,
    output reg [NB_DATA        - 1 : 0] o_regfile_data,
    output reg [NB_DATA        - 1 : 0] o_dmem_data   ,

    // Inputs
    input                           i_du_rgfile_rd,  //! DU regfile read enable input
    input [4 : 0]                   i_regfile_addr,  //! Register File read address input
    input [NB_DATA         - 1 : 0] i_imem_data   ,  //! Instruction memory input
    input [IMEM_ADDR_WIDTH - 1 : 0] i_imem_waddr  ,  //! Instrunction memory write address input
    input [1 : 0]                   i_imem_size   ,  //! Instruction memory write size input
    input                           i_imem_wen    ,  //! Instruction memory write enable input
    input [DMEM_ADDR_WIDTH - 1 : 0] i_dmem_raddr  ,  //! Data memory read address input
    input [1 : 0]                   i_dmem_rsize  ,  //! Data memory read size input
    input                           i_dmem_ren    ,  //! Data memory read enable input
    input                           i_en          ,  //! Enable signal input
    input                           i_du_rst      ,  //! Debug Unit reset input
    input                           i_rst         ,
    input                           clk           
);

    //! Local Parameters
    localparam NB_CTRL = 12;                               //! NB of control
    
    // PC output connections
    wire [NB_PC - 1 : 0] pc_out;                           //! Program Counter output connection
    
    // PC's adder output connections
    wire [NB_PC - 1 : 0] pc_adder_out;                     //! Program Counter's adder to mux connection
    
    // PC's mux output connections
    wire [NB_PC - 1 : 0] mux2to1_to_pc;                    //! Mux to Program Counter connection
    
    // Instruction Memory output connections
    wire [NB_INSTRUCTION - 1 : 0] imem_to_if_id_reg;       //! Instruction memory to IF/ID reg connection
    
    // Debug Unit Register File addr1 Mux output connections
    wire [4 : 0] du_regfile_addr1_mux_out;
    
    // IF/ID Register output connections
    wire [NB_PC          - 1 : 0] if_id_pc_out         ;   //! PC from IF/ID reg connection
    wire [NB_PC          - 1 : 0] if_id_pc_next_out    ;   //! PC+4 from IF/ID reg connection
    wire [NB_INSTRUCTION - 1 : 0] if_id_instruction_out;   //! Instruction from IF/ID reg connection
    wire [6 : 0]                  if_id_opcode_out     ;
    wire [4 : 0]                  if_id_rd_addr_out    ;
    wire [2 : 0]                  if_id_func3_out      ;
    wire [4 : 0]                  if_id_rs1_addr_out   ;
    wire [4 : 0]                  if_id_rs2_addr_out   ;
    wire [6 : 0]                  if_id_func7_out      ;
    
    // Base Integer Register File output connections
    wire [NB_DATA - 1 : 0] int_regfile_data1_to_id_ex_reg;  //! Integer Refile data1 to ID/EX pipelinereg
    wire [NB_DATA - 1 : 0] int_regfile_data2_to_id_ex_reg;  //! Integer Refile data2 to ID/EX pipelinereg
    
    // Immediate Generator output connections
    wire [NB_DATA - 1 : 0] imm_out;                         //! Immediate Generator output connection
    
    // Control Unit output connections
    wire [NB_CTRL - 1 : 0] ctrl_unit_out;
    
    // Hazard Detection Unit output connections
    wire hdu_pcWrite_to_pc       ;
    wire hdu_IfIdWrite_to_IfIdReg;
    wire hdu_to_nop_mux          ;
    
    // Hazard Detection Unit Mux (NOP insertion Mux) connections
    wire [NB_CTRL        - 1 : 0] id_nop_insert_mux_out;
    
    // ID/EX Register output connections
    wire                          id_ex_regWrite_out;
    wire                          id_ex_memRead_out ;
    wire                          id_ex_memWrite_out;
    wire                          id_ex_ALUSrc_out  ;
    wire                          id_ex_memToReg_out;
    wire                          id_ex_jump_out    ;
    wire                          id_ex_linkReg_out ;
    wire [1 : 0]                  id_ex_ALUOp_out   ;
    wire [1 : 0]                  id_ex_dataSize_out;
    wire [NB_PC          - 1 : 0] id_ex_pc_out      ;  //! PC from ID/EX reg connection
    wire [NB_PC          - 1 : 0] id_ex_pc_next_out ;  //! PC+4 from ID/EX reg connection
    wire [NB_DATA        - 1 : 0] id_ex_imm_out     ;  //! ID/EX Immediate output connection
    wire [NB_DATA        - 1 : 0] id_ex_rs1_data_out;  //! ID/EX rs1 reg output connection
    wire [NB_DATA        - 1 : 0] id_ex_rs2_data_out;  //! ID/EX rs1 reg output connection
    wire [4 : 0]                  id_ex_rd_addr_out ;
    wire [2 : 0]                  id_ex_func3_out   ;
    wire [4 : 0]                  id_ex_rs1_addr_out;
    wire [4 : 0]                  id_ex_rs2_addr_out;
    wire [6 : 0]                  id_ex_func7_out   ;
    
    // Branch Control Unit output connections
    wire [1 : 0] branch_ctrl_unit_pc_out;
    wire         branch_flush_out;
    
    // Branch target Address Calculator Adder output connections
    wire [NB_DATA - 1 : 0] branch_adder_addr_out;
    
    // EX Forwarding Unit output connections
    wire [1 : 0] fowrward_unit_a_out;
    wire [1 : 0] fowrward_unit_b_out;
    
    // Forwarding Muxes output connections
    wire [NB_DATA - 1 : 0] forwarding_mux_a_out;
    wire [NB_DATA - 1 : 0] forwarding_mux_b_out;
    wire [NB_DATA - 1 : 0] forwarding_mux_c_out;
    
    // ALU output connections
    wire [NB_DATA - 1 : 0] alu_result;
    
    // ALU Control Unit output connections
    wire [3 : 0] alu_op_out;
    
    // EX/MEM Register output connections
    wire                   ex_mem_regWrite_out   ;
    wire                   ex_mem_memRead_out    ;
    wire                   ex_mem_memWrite_out   ;
    wire                   ex_mem_memToReg_out   ;
    wire                   ex_mem_branch_out     ;
    wire                   ex_mem_jump_out       ;
    wire                   ex_mem_linkReg_out    ;
    wire [1 : 0]           ex_mem_dataSize_out   ;
    wire [NB_PC   - 1 : 0] ex_mem_pc_next_out    ;  //! PC+4 signal from EX/MEM reg connection
    wire [NB_PC   - 1 : 0] ex_mem_branch_addr_out;
    wire [NB_DATA - 1 : 0] ex_mem_alu_out        ;  //! ALU result from EX/MEM reg connection
    wire [NB_DATA - 1 : 0] ex_mem_data_out       ;
    wire [4 : 0]           ex_mem_rd_addr_out    ;
    wire [2 : 0]           ex_mem_func3_out      ;
    
    // Debug Unit's Data Memory Read Mux
    wire [DMEM_ADDR_WIDTH - 1 : 0] dmem_addr_mux_out;
    
    // Data Memory output conenctions
    wire [NB_DATA - 1 : 0] data_memory_out;
    
    // Data Memory Output Unit output connections
    wire [NB_DATA - 1 : 0] data_mem_output_unit_data_out;
    
    // MEM/WB Register output connections
    wire                          mem_wb_regWrite_out;
    wire                          mem_wb_memToReg_out;
    wire                          mem_wb_jump_out    ;
    wire [4 : 0]                  mem_wb_rd_addr_out ; 
    wire [NB_PC          - 1 : 0] mem_wb_pc_next_out ;  //! PC+4 signal from MEM/WB reg connection
    wire [NB_DATA        - 1 : 0] mem_wb_data_out    ;  //! Data memory output from MEM/WB reg connection
    wire [NB_DATA        - 1 : 0] mem_wb_alu_out     ;  //! ALU result output from MEM/WB reg connection
    wire [2 : 0]                  mem_wb_func3_out   ;
    
    // WB Mux output connections
    wire [NB_DATA - 1 : 0] wb_mux_out;
    
    reg                           en             ;
    reg                           du_rgfile_rd_in;
    reg [4 : 0]                   regfile_addr_in;
    reg [NB_DATA         - 1 : 0] imem_data_in   ;
    reg [IMEM_ADDR_WIDTH - 1 : 0] imem_waddr_in  ;
    reg [1 : 0]                   imem_size_in   ;
    reg                           imem_wen_in    ;
    reg [DMEM_ADDR_WIDTH - 1 : 0] dmem_raddr_in  ;
    reg [1 : 0]                   dmem_rsize_in  ;
    reg                           dmem_ren_in    ;
    reg                           du_rst         ;
    reg                           flush          ;

    always @(posedge clk) begin
        if (i_rst) begin
            en              <= 1'b0                          ;
            du_rst          <= 1'b0                          ;
            o_pc            <= pc_out                        ;
            o_instr         <= imem_to_if_id_reg             ;
            o_regfile_data  <= int_regfile_data1_to_id_ex_reg;
            o_dmem_data     <= data_memory_out               ;
            du_rgfile_rd_in <= i_du_rgfile_rd                ;
            regfile_addr_in <= i_regfile_addr                ;
            imem_data_in    <= i_imem_data                   ;
            imem_waddr_in   <= i_imem_waddr                  ;
            imem_size_in    <= i_imem_size                   ;
            imem_wen_in     <= i_imem_wen                    ;
            dmem_raddr_in   <= i_dmem_raddr                  ;
            dmem_rsize_in   <= i_dmem_rsize                  ;
            dmem_ren_in     <= i_dmem_ren                    ;
            flush           <= branch_flush_out              ;
        end
        else begin
            en              <= i_en                          ;
            du_rst          <= i_du_rst                      ;
            o_pc            <= pc_out                        ;
            o_instr         <= imem_to_if_id_reg             ;
            o_regfile_data  <= int_regfile_data1_to_id_ex_reg;
            o_dmem_data     <= data_memory_out               ;
            du_rgfile_rd_in <= i_du_rgfile_rd                ;
            regfile_addr_in <= i_regfile_addr                ;
            imem_data_in    <= i_imem_data                   ;
            imem_waddr_in   <= i_imem_waddr                  ;
            imem_size_in    <= i_imem_size                   ;
            imem_wen_in     <= i_imem_wen                    ;
            dmem_raddr_in   <= i_dmem_raddr                  ;
            dmem_rsize_in   <= i_dmem_rsize                  ;
            dmem_ren_in     <= i_dmem_ren                    ;
            flush           <= branch_flush_out              ;
        end
    end
    
    
    //
    // Instruction Fetch Stage Modules
    //
    
    // PC's Adder
    adder
    #(
        .NB_ADDER (NB_PC)
    )
        u_pc_adder
        (
            .o_sum (pc_adder_out),
            .i_a   (pc_out      ),
            .i_b   (32'h4       )   //! PC increments by 4
        );
    
    // PC's Mux
    mux_3to1
    #(
        .DATA_WIDTH (NB_PC)
    )
        u_pc_in_mux
        (
            .o_data  (mux2to1_to_pc          ),
            .i_data0 (pc_adder_out           ),  // PC+4
            .i_data1 (ex_mem_branch_addr_out ),  // Branches
            .i_data2 (ex_mem_alu_out         ),  // JALR
            .i_sel   (branch_ctrl_unit_pc_out)
        ); 

    // Program Counter
    pc
    #(
        .NB_PC (NB_PC)
    )
        u_pc
        (
            .o_pc  (pc_out                  ),
            .i_pc  (mux2to1_to_pc           ),
            .i_en  (hdu_pcWrite_to_pc & en),
            .i_rst (i_rst | du_rst          ),
            .clk   (clk                     )
        );
    
    // Instruction Memory
    memory
    #(
        .ADDR_WIDTH (IMEM_ADDR_WIDTH)
    )
        u_instruction_memory
        (
            .o_dout  (imem_to_if_id_reg              ),
            .i_din   (imem_data_in                   ),
            .i_waddr (imem_waddr_in                  ),
            .i_raddr (pc_out[IMEM_ADDR_WIDTH - 1 : 0]),  // Truncate the address to fit the memory's address width
            .i_size  (imem_size_in                   ),  // FIXME
            .i_wen   (imem_wen_in                    ),
            .i_ren   (~imem_wen_in & en              ),
            .clk     (clk                            ) 
        );
    
    // IF/ID Pipeline Registers
    if_id_reg
    #(
        .NB_INSTR (NB_INSTRUCTION),
        .NB_PC    (NB_PC          )
    )
        u_if_id_reg
        (
            .o_pc       (if_id_pc_out                   ),
            .o_pc_next  (if_id_pc_next_out              ),
            .o_instr    (if_id_instruction_out          ),
            .o_opcode   (if_id_opcode_out               ),
            .o_rd_add   (if_id_rd_addr_out              ),
            .o_func3    (if_id_func3_out                ),
            .o_rs1_addr (if_id_rs1_addr_out             ),
            .o_rs2_addr (if_id_rs2_addr_out             ),
            .o_func7    (if_id_func7_out                ),
            .i_instr    (imem_to_if_id_reg              ),  
            .i_pc       (pc_out                         ),
            .i_pc_next  (pc_adder_out                   ),
            .i_flush    (branch_flush_out | flush       ),   
            .i_en       (hdu_IfIdWrite_to_IfIdReg & en),  
            .i_rst      (i_rst | du_rst                 ),  
            .clk        (clk                            ) 
        );
    
    //
    // Instruction Decode/Register File Read Stage Modules
    //
    
    // Debug Unit Register File addr1 Mux
    mux_2to1
    #(
        .NB_MUX (5)
    )
        u_du_regfile_mux
        (
            .o_mux (du_regfile_addr1_mux_out),
            .i_a   (if_id_rs1_addr_out      ),
            .i_b   (regfile_addr_in         ),
            .i_sel (du_rgfile_rd_in         )
        );
    
    // Integer Register File
    regfile
    #(
        .DATA_WIDTH (NB_DATA)
    )
        u_integer_regfile
        (
            .o_dout1 (int_regfile_data1_to_id_ex_reg),
            .o_dout2 (int_regfile_data2_to_id_ex_reg),
            .i_addr1 (du_regfile_addr1_mux_out      ),
            .i_addr2 (if_id_rs2_addr_out            ),
            .i_waddr (mem_wb_rd_addr_out            ),
            .i_wdata (wb_mux_out                    ),
            .i_wen   (mem_wb_regWrite_out & en    ),
            .i_rst   (i_rst | du_rst                ),
            .clk     (clk                           ) 
        );
    
    // Immediate Generator
    imm_gen
    #(
        .DATA_WIDTH (NB_INSTRUCTION)
    )
        u_imm_gen
        (
            .o_imm   (imm_out              ),
            .i_instr (if_id_instruction_out) 
        );
    
    // Base Integer Control Unit
    base_integer_ctrl_unit
    #(
        .NB_CTRL (NB_CTRL)
    )
        u_base_integer_ctrl_unit
        (
            .o_ctrl   (ctrl_unit_out   ),
            .i_opcode (if_id_opcode_out),
            .i_func3  (if_id_func3_out )
        );
    
    // Hazard Detection Unit
    hazard_detection_unit
        u_hazard_detection_unit
        (
            .o_pc_write       (hdu_pcWrite_to_pc       ),
            .o_if_id_write    (hdu_IfIdWrite_to_IfIdReg),
            .o_control_mux    (hdu_to_nop_mux          ),
            .i_id_ex_mem_read (id_ex_memRead_out       ),
            .i_id_ex_rd       (id_ex_rd_addr_out       ),
            .i_if_id_rs1      (if_id_rs1_addr_out      ),
            .i_if_id_rs2      (if_id_rs2_addr_out      )
        );
    
    // NOP Instruction Mux
    mux_2to1
    #(
        .NB_MUX (NB_CTRL)
    )
        u_nop_insertion_mux
        (
            .o_mux (id_nop_insert_mux_out),
            .i_a   (ctrl_unit_out        ),
            .i_b   ({NB_CTRL{1'b0}}      ),
            .i_sel (hdu_to_nop_mux       ) 
        );
    
    // ID/EX Pipeline Registers
    id_ex_reg
    #(
        .NB_PC      (NB_PC  ),
        .DATA_WIDTH (NB_DATA),
        .NB_CTRL    (NB_CTRL)
    )
        u_id_ex_reg
        (
            .o_regWrite (id_ex_regWrite_out            ),
            .o_memRead  (id_ex_memRead_out             ),
            .o_memWrite (id_ex_memWrite_out            ),
            .o_ALUSrc   (id_ex_ALUSrc_out              ),
            .o_memToReg (id_ex_memToReg_out            ),
            .o_branch   (id_ex_branch_out              ),
            .o_jump     (id_ex_jump_out                ),
            .o_linkReg  (id_ex_linkReg_out             ),
            .o_ALUOp    (id_ex_ALUOp_out               ),
            .o_dataSize (id_ex_dataSize_out            ),
            .o_pc       (id_ex_pc_out                  ),
            .o_pc_next  (id_ex_pc_next_out             ),
            .o_rs1_data (id_ex_rs1_data_out            ),
            .o_rs2_data (id_ex_rs2_data_out            ),
            .o_imm      (id_ex_imm_out                 ),
            .o_rd_addr  (id_ex_rd_addr_out             ),
            .o_func3    (id_ex_func3_out               ),
            .o_rs1_addr (id_ex_rs1_addr_out            ),
            .o_rs2_addr (id_ex_rs2_addr_out            ),
            .o_func7    (id_ex_func7_out               ),
            .i_ctrl     (id_nop_insert_mux_out         ),
            .i_pc       (if_id_pc_out                  ),
            .i_pc_next  (if_id_pc_next_out             ),
            .i_rs1_data (int_regfile_data1_to_id_ex_reg),
            .i_rs2_data (int_regfile_data2_to_id_ex_reg),
            .i_imm      (imm_out                       ),
            .i_rd_addr  (if_id_rd_addr_out             ),
            .i_func3    (if_id_func3_out               ),
            .i_rs1_addr (if_id_rs1_addr_out            ),
            .i_rs2_addr (if_id_rs2_addr_out            ),
            .i_func7    (if_id_func7_out               ),
            .i_flush    (branch_flush_out              ),
            .i_en       (en                            ),
            .clk        (clk                           ) 
        );
    
    //
    // Execution/Address Calculation Stage Modules
    //
    
    // Forwarding Mux 1
    mux_3to1
    #(
        .DATA_WIDTH (NB_DATA)
    )
        u_forwarding_mux_1
        (
            .o_data  (forwarding_mux_a_out), 
            .i_data0 (id_ex_rs1_data_out  ),
            .i_data1 (wb_mux_out          ),
            .i_data2 (ex_mem_alu_out      ),
            .i_sel   (fowrward_unit_a_out ) 
        );
    
    // Forwarding Mux 2 / ALU input mux
    mux_4to1
    #(
        .DATA_WIDTH (NB_DATA)
    )
        u_forwarding_mux_2
        (
            .o_data  (forwarding_mux_b_out                                                                  ), 
            .i_data0 (id_ex_rs2_data_out                                                                    ),
            .i_data1 (wb_mux_out                                                                            ),
            .i_data2 (ex_mem_alu_out                                                                        ),
            .i_data3 (id_ex_imm_out                                                                         ),
            .i_sel   ({fowrward_unit_b_out[1] | id_ex_ALUSrc_out, fowrward_unit_b_out[0] | id_ex_ALUSrc_out}) 
        );
    
    // Forwarding Mux 3 & ALU input mux
    mux_3to1
    #(
        .DATA_WIDTH (NB_DATA)
    )
        u_forwarding_mux_3
        (
            .o_data  (forwarding_mux_c_out), 
            .i_data0 (id_ex_rs2_data_out  ),
            .i_data1 (wb_mux_out          ),
            .i_data2 (ex_mem_alu_out      ),
            .i_sel   (fowrward_unit_b_out ) 
        );
    
    // ALU
    alu
    #(
        .NB_DATA (NB_DATA)
    )
        u_alu
        (
            .o_result      (alu_result          ),
            .i_data1       (forwarding_mux_a_out),
            .i_data2       (forwarding_mux_b_out),
            .i_alu_op      (alu_op_out          ) 
        );
    
    // ALU Control Unit
    alu_ctrl_unit
        u_alu_ctrl_unit
        (
            .o_alu_op (alu_op_out     ),     
            .i_alu_op (id_ex_ALUOp_out),
            .i_funct7 (id_ex_func7_out),
            .i_funct3 (id_ex_func3_out)
        );

    // EX Forwarding Unit
    ex_forwarding_unit
        u_ex_forwarding_unit
        (
            .o_forward_a    (fowrward_unit_a_out),   
            .o_forward_b    (fowrward_unit_b_out),             
            .i_ex_rs1       (id_ex_rs1_addr_out ),
            .i_ex_rs2       (id_ex_rs2_addr_out ),
            .i_mem_rd       (ex_mem_rd_addr_out ),
            .i_wb_rd        (mem_wb_rd_addr_out ),
            .i_mem_RegWrite (ex_mem_regWrite_out),
            .i_wb_RegWrite  (mem_wb_regWrite_out)
        );
    
    // Branch target Address Calculator Adder
    adder
    #(
        .NB_ADDER (NB_PC)
    )
        u_branch_target_adder
        (
            .o_sum (branch_adder_addr_out),
            .i_a   (id_ex_pc_out         ),
            .i_b   (id_ex_imm_out        )
        );
    
    // EX/MEM Pipeline Registers
    ex_mem_reg
    #(
        .NB_PC      (NB_PC  ),
        .DATA_WIDTH (NB_DATA)
    )
        u_ex_mem_reg
        (
            .o_regWrite    (ex_mem_regWrite_out      ),
            .o_memRead     (ex_mem_memRead_out       ),
            .o_memWrite    (ex_mem_memWrite_out      ),
            .o_memToReg    (ex_mem_memToReg_out      ),
            .o_branch      (ex_mem_branch_out        ),
            .o_jump        (ex_mem_jump_out          ),
            .o_linkReg     (ex_mem_linkReg_out       ),
            .o_dataSize    (ex_mem_dataSize_out      ),
            .o_pc_next     (ex_mem_pc_next_out       ),
            .o_branch_addr (ex_mem_branch_addr_out   ),
            .o_alu         (ex_mem_alu_out           ),
            .o_data2       (ex_mem_data_out          ),
            .o_rd_addr     (ex_mem_rd_addr_out       ),
            .o_func3       (ex_mem_func3_out         ),
            .i_regWrite    (id_ex_regWrite_out       ),
            .i_memRead     (id_ex_memRead_out        ),
            .i_memWrite    (id_ex_memWrite_out       ),
            .i_memToReg    (id_ex_memToReg_out       ),
            .i_branch      (id_ex_branch_out         ),
            .i_jump        (id_ex_jump_out           ),
            .i_linkReg     (id_ex_linkReg_out        ),
            .i_dataSize    (id_ex_dataSize_out       ),
            .i_pc_next     (id_ex_pc_next_out        ),
            .i_branch_addr (branch_adder_addr_out    ),
            .i_alu         (alu_result               ),
            .i_data2       (forwarding_mux_c_out     ),
            .i_rd_addr     (id_ex_rd_addr_out        ),
            .i_func3       (id_ex_func3_out          ),
            .i_flush       (branch_flush_out         ),
            .i_en          (en                       ),
            .i_rst         (i_rst | du_rst           ),
            .clk           (clk                      ) 
        );
    
    //
    // Memory Access Stage Modules
    //

    branch_ctrl_unit
        u_branch_ctrl_unit
        (
            .o_pcSrc      (branch_ctrl_unit_pc_out   ),
            .o_flush      (branch_flush_out          ),
            .i_alu_result (ex_mem_alu_out[0]         ),
            .i_alu_zero   (~ex_mem_alu_out[0]        ),
            .i_branch     (ex_mem_branch_out         ),
            .i_jump       (ex_mem_jump_out           ),
            .i_linkReg    (ex_mem_linkReg_out        ),
            .i_func3_0    (ex_mem_func3_out[0]       ),
            .i_func3_2    (ex_mem_func3_out[2]       )
        );
    
    // Debug Unit's Data Memory Read Mux
    mux_2to1
    #(
        .NB_MUX (DMEM_ADDR_WIDTH)
    )
        u_du_dmem_mux
        (
            .o_mux (dmem_addr_mux_out                      ),
            .i_a   (ex_mem_alu_out[DMEM_ADDR_WIDTH - 1 : 0]),
            .i_b   (dmem_raddr_in                          ),
            .i_sel (dmem_ren_in                            )
        );
    
    // Data Memory
    memory
    #(
        .ADDR_WIDTH (DMEM_ADDR_WIDTH)
    )
        u_data_memory
        (
            .o_dout  (data_memory_out                        ),
            .i_din   (ex_mem_data_out                        ),
            .i_waddr (ex_mem_alu_out[DMEM_ADDR_WIDTH - 1 : 0]),  // Truncate the address to fit the memory's address width
            .i_raddr (dmem_addr_mux_out                      ),  
            .i_size  (ex_mem_dataSize_out | dmem_rsize_in    ),
            .i_wen   (ex_mem_memWrite_out                    ),
            .i_ren   (ex_mem_memRead_out | dmem_ren_in       ),
            .clk     (clk                                    ) 
        );
    
    // MEM/WB Pipeline Registers
    mem_wb_reg
    #(
        .NB_PC      (NB_PC  ),
        .DATA_WIDTH (NB_DATA)
    )
        u_mem_wb_reg
        (
            .o_regWrite (mem_wb_regWrite_out),
            .o_memToReg (mem_wb_memToReg_out),
            .o_jump     (mem_wb_jump_out    ),
            .o_pc_next  (mem_wb_pc_next_out ),
            .o_data     (mem_wb_data_out    ),
            .o_alu      (mem_wb_alu_out     ),
            .o_rd_addr  (mem_wb_rd_addr_out ),
            .o_func3    (mem_wb_func3_out   ),
            .i_regWrite (ex_mem_regWrite_out),
            .i_memToReg (ex_mem_memToReg_out),
            .i_jump     (ex_mem_jump_out    ),
            .i_pc_next  (ex_mem_pc_next_out ),
            .i_data     (data_memory_out    ),
            .i_alu      (ex_mem_alu_out     ),
            .i_rd_addr  (ex_mem_rd_addr_out ),
            .i_func3    (ex_mem_func3_out   ),
            .i_en       (en                 ),
            .clk        (clk                ) 
        );
    
    //
    // Write Back Stage Modules
    //

    // Data Memory Output Unit
    data_mem_output_unit
    #(
        .DATA_WIDTH (NB_DATA)
    )
        u_data_mem_ctrl_unit
        (
            .o_data   (data_mem_output_unit_data_out),
            .i_data   (mem_wb_data_out              ),
            .i_func3  (mem_wb_func3_out             )
        );
    
    // WB Mux
    mux_4to1
    #(
        .DATA_WIDTH (NB_DATA)
    )
        u_wb_mux
        (
            .o_data  (wb_mux_out                            ),
            .i_data0 (mem_wb_alu_out                        ),
            .i_data1 (data_mem_output_unit_data_out         ),
            .i_data2 (mem_wb_pc_next_out                    ),
            .i_data3 ({NB_DATA{1'b0}}                       ),
            .i_sel   ({mem_wb_jump_out, mem_wb_memToReg_out}) 
        );
    
endmodule