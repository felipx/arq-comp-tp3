
module if_if_stages_tb (
    
);
    parameter NB_PC              = 32;  //! NB of Program Counter
    parameter NB_INSTRUCTION     = 32;  //! Size of each memory location
    parameter NB_DATA            = 32;  //! Size of Integer Base registers
    parameter IMEM_ADDR_WIDTH    = 5 ;  //! Instruction Memory address width
    parameter DMEM_ADDR_WIDTH    = 5 ;  //! Data Memory address width
    parameter NB_CTRL            = 11;  //! NB of control

    parameter NB_RND         = 32;

    localparam IMEM_DATA_DEPTH = 2**IMEM_ADDR_WIDTH;


    reg i_rst;
    reg clk  ;
    reg en   ;

    // IMEM inputs
    reg [NB_DATA         - 1 : 0] i_imem_data ;
    reg [IMEM_ADDR_WIDTH - 1 : 0] i_imem_waddr;
    reg                           i_imem_wen  ;
    reg [1 : 0]                   i_imem_wsize ;

    // regfile inputs
    reg [4           : 0] i_regfile_waddr;
    reg [NB_DATA - 1 : 0] i_regfile_data ;
    reg                   i_regfile_wen  ;

    reg  [NB_RND - 1 : 0] rnd;

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
        .DATA_WIDTH (NB_PC)
    )
        u_pc_mux_3to1
        (
            .o_data  (mux2to1_to_pc       ),
            .i_data0 (pc_adder_out_connect),  // PC+4
            .i_data1 ({NB_PC{1'b0}}       ),  // JAL and Branches
            .i_data2 ({NB_PC{1'b0}}       ),  // JALR
            .i_sel   (2'b00               )
        );

    // Program Counter
    pc
    #(
        .NB_PC (NB_PC)
    )
        u_pc
        (
            .o_pc  (pc_out_connect        ),
            .i_pc  (mux2to1_to_pc         ),
            .i_en  (hdu_pcWrite_to_pc & en),
            .i_rst (i_rst                 ),
            .clk   (clk                   )
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
            .i_wsize (i_imem_wsize                           ),
            .i_wen   (i_imem_wen                             ),
            .i_ren   (~i_imem_wen                             ),  // TODO: Check if OK
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
            .i_flush   (1'b0                              ),   
            .i_en      (hdu_IfIdWrite_to_IfIdReg & en     ),  
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
            .i_waddr (i_regfile_waddr                       ),
            .i_wdata (i_regfile_data                        ),
            .i_wen   (i_regfile_wen                         ),
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
        .DATA_WIDTH (NB_CTRL)
    )
        u_nop_insertion_mux
        (
            .o_data  (id_nop_insert_mux_out_connect                       ),
            .i_data0 (ctrl_unit_out_connect                               ),
            .i_data1 ({NB_CTRL{1'b0}}                                     ),
            .i_data2 ({NB_CTRL{1'b0}}                                     ),
            .i_data3 ({NB_CTRL{1'b0}}                                     ),
            .i_sel   ({hdu_to_nop_mux, 1'b0}) 
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
            .i_en       (1'b1 & en                                  ),
            .i_rst      (i_rst                                      ),
            .clk        (clk                                        ) 
        );

    integer i;

    initial begin

        $display("Starting IF/ID Stages Testbench");

        clk   = 1'b0;
        i_rst = 1'b0;
        en    = 1'b0;

        i_imem_data  = {NB_INSTRUCTION{1'b0}};
        i_imem_waddr = {IMEM_DATA_DEPTH{1'b0}};
        i_imem_wen   = 1'b0;
        i_imem_wsize = 2'b00;

        i_regfile_waddr  = 5'b00000;
        i_regfile_data   = {NB_DATA{1'b0}};
        i_regfile_wen    = 1'b0;

        #20 i_rst = 1'b1;
        #20 i_rst = 1'b0;

        $display("Load data into regfile");

        for (i = 0; i < 31; i = i + 1) begin
            #10 rnd             = $random;
                i_regfile_waddr = i;
                if (i == 2) begin
                    i_regfile_data  = 32'h2;    
                end
                else begin
                    i_regfile_data  = rnd;    
                end
            #10 i_regfile_wen   = 1'b1;
            #10 i_regfile_wen   = 1'b0;
        end

        $display("Load instructions in imem");

        i_imem_wsize = 2'b11;

        // sub x2, x1, x3
        i_imem_data  = 32'b0100000_00011_00001_000_00010_0110011;
        i_imem_waddr = i_imem_waddr + 1'b0;

        #10 i_imem_wen = 1'b1;

        // and x12, x2, x5
        #10 i_imem_data  = 32'b0000000_00101_00010_111_01100_0110011;
            i_imem_waddr = i_imem_waddr + 4'd4;

        // or x13, x6, x2
        #10 i_imem_data  = 32'b0000000_00010_00110_110_01101_0110011;
            i_imem_waddr = i_imem_waddr + 4'd4;

        // add x14, x2, x2
        #10 i_imem_data  = 32'b0000000_00010_00010_000_01110_0110011;
            i_imem_waddr = i_imem_waddr + 4'd4;

        // sw x15, 10(x2)
        #10 i_imem_data  = 32'b0000000_01111_00010_010_01010_0100011;
            i_imem_waddr = i_imem_waddr + 4'd4; 

        #10 i_imem_wen = 1'b0;

            en = 1'b1; 

        #100;

        #20 $display("IF/ID Stages Testbench finished");
        #20 $finish;
        
    end

    always #5 clk = ~clk;
endmodule