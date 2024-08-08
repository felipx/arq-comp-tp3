`timescale 1ns/100ps

module id_stage_tb ();

    parameter NB_INSTRUCTION = 32;
    parameter NB_PC          = 32;
    parameter NB_DATA        = 32;
    parameter NB_CTRL        = 11;
    parameter NB_RND         = 32;

    // IF/ID inputs
    reg [NB_INSTRUCTION - 1 : 0] i_instr         ;
    reg [NB_PC          - 1 : 0] i_pc            ;
    reg [NB_PC          - 1 : 0] i_pc_next       ;
    reg                          if_id_reg_enable;

    // IF/ID outputs
    wire [NB_INSTRUCTION - 1 : 0] if_id_instruction_out_connect;
    wire [NB_PC          - 1 : 0] if_id_pc_out_connect         ;
    wire [NB_PC          - 1 : 0] if_id_pc_next_out_connect    ;

    // regfile inputs
    reg [4           : 0] i_regfile_waddr;
    reg [NB_DATA - 1 : 0] i_regfile_data ;
    reg                   i_regfile_wen  ;

    // regfile outputs
    wire [NB_DATA - 1 : 0] int_regfile_data1_to_id_ex_reg;
    wire [NB_DATA - 1 : 0] int_regfile_data2_to_id_ex_reg;

    // Imm gen output
    wire [NB_DATA - 1 : 0] imm_out_connect;

    // Control Unit output
    wire [NB_CTRL - 1 : 0] ctrl_unit_out_connect;

    // ID/EX outputs
    wire [NB_DATA        - 1 : 0] id_ex_ctrl_out_connect       ;
    wire [NB_PC          - 1 : 0] id_ex_pc_out_connect         ;
    wire [NB_PC          - 1 : 0] id_ex_pc_next_out_connect    ;
    wire [NB_DATA        - 1 : 0] id_ex_imm_out_connect        ;
    wire [NB_DATA        - 1 : 0] id_ex_rs1_data_out_connect   ;
    wire [NB_DATA        - 1 : 0] id_ex_rs2_data_out_connect   ;
    wire [NB_INSTRUCTION - 1 : 0] id_ex_instruction_out_connect;
    
    
    reg  [NB_RND - 1 : 0] rnd  ;
    reg                  i_rst;
    reg                  clk  ;


    // IF/ID Pipeline Register
    if_id_reg
    #(
        .NB_INSTR (NB_INSTRUCTION),
        .NB_PC    (NB_PC          )
    )
        u_if_id_reg
        (
            .o_instr   (if_id_instruction_out_connect),
            .o_pc      (if_id_pc_out_connect         ),
            .o_pc_next (if_id_pc_next_out_connect    ),
            .i_instr   (i_instr                      ),  
            .i_pc      (i_pc                         ),
            .i_pc_next (i_pc_next                    ),   
            .i_en      (if_id_reg_enable             ),  
            .i_rst     (i_rst                        ),  
            .clk       (clk                          ) 
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
    
    //// Hazard Detection Unit
    //hazard_detection_unit
    //#()
    //    u_hazard_detection_unit
    //    (
    //        .o_pc_write       (hdu_pcWrite_to_pc                     ),
    //        .o_if_id_write    (hdu_IfIdWrite_to_IfIdReg              ),
    //        .o_control_mux    (hdu_to_nop_mux                        ),
    //        .i_id_ex_mem_read (id_ex_ctrl_out_connect[1]             ),
    //        .i_id_ex_rd       (id_ex_instruction_out_connect[11 :  7]),
    //        .i_if_id_rs1      (if_id_instruction_out_connect[19 : 15]),
    //        .i_if_id_rs2      (if_id_instruction_out_connect[24 : 20])
    //    );
    //
    //// NOP Instruction Mux
    //mux_2to1
    //#(
    //    .NB_MUX (NB_CTRL)
    //)
    //    u_nop_insertion_mux
    //    (
    //        o_mux (hdu_mux_to_id_ex_reg ),
    //        i_a   (ctrl_unit_out_connect),
    //        i_b   ({NB_CTRL{1'b0}}      ),
    //        i_sel (hdu_to_nop_mux       ) 
    //    );
    
    // ID/EX Pipeline Register
    id_ex_reg
    #(
        .DATA_WIDTH (NB_DATA)
    )
        u_id_ex_reg
        (
            .o_ctrl     (id_ex_ctrl_out_connect            ),
            .o_pc       (id_ex_pc_out_connect              ),
            .o_pc_next  (id_ex_pc_next_out_connect         ),
            .o_rs1_data (id_ex_rs1_data_out_connect        ),
            .o_rs2_data (id_ex_rs2_data_out_connect        ),
            .o_imm      (id_ex_imm_out_connect             ),
            .o_instr    (id_ex_instruction_out_connect     ),
            .i_ctrl     ({{21{1'b0}}, ctrl_unit_out_connect}),
            .i_pc       (if_id_pc_out_connect              ),
            .i_pc_next  (if_id_pc_next_out_connect         ),
            .i_rs1_data (int_regfile_data1_to_id_ex_reg    ),
            .i_rs2_data (int_regfile_data2_to_id_ex_reg    ),
            .i_imm      (imm_out_connect                   ),
            .i_instr    (if_id_instruction_out_connect     ),
            .i_en       (1'b1                              ),  //TODO: check if OK
            .i_rst      (i_rst                             ),
            .clk        (clk                               ) 
        );

    integer i;    
    
    initial begin
        $display("Starting ID_Stage Testbench");

        clk              = 1'b0;

        i_instr          = {NB_INSTRUCTION{1'b0}};
        i_pc             = {NB_PC{1'b0}};
        i_pc_next        = {NB_PC{1'b0}};
        if_id_reg_enable = 1'b0;

        i_regfile_waddr  = 5'b00000;
        i_regfile_data   = {NB_DATA{1'b0}};
        i_regfile_wen    = 1'b0;

        i_rst = 1'b0;

        #20 i_rst = 1'b1;
        #20 i_rst = 1'b0;

        $display("Load data into regfile");

        for (i = 0; i < 31; i = i + 1) begin
            #10 rnd             = $random;
                i_regfile_waddr = i;
                i_regfile_data  = rnd;
            #10 i_regfile_wen   = 1'b1;
            #10 i_regfile_wen   = 1'b0;
        end

        $display("Load data into IF/ID");
        $display("instr = sw a2, 0x222(a3)");

        #10 i_pc      = 32'h0000_0004;
            i_pc_next = 32'h0000_0008;
            i_instr   = 32'b0010001_00010_00011_010_00010_0100011;

        #10 if_id_reg_enable = 1'b1;

        #20 $display("ID_stage Testbench finished");
        #20 $finish;

    end

    always #5 clk = ~clk;
endmodule