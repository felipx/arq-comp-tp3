module id_ex_reg
#(
    parameter NB_PC           = 32,  //! NB of Program Counter
    parameter NB_CTRL         = 10,  //! Width of the control signals
    parameter NB_REGFILE_ADDR = 5 ,  //! Register File's address width
    parameter DATA_WIDTH      = 32   //! NB of Data
    
) (
    // Outputs
    output [DATA_WIDTH      - 1 : 0] o_instr,  //! Instruction output
    output [NB_PC           - 1 : 0] o_pc   ,  //! Program Counter output
    output [DATA_WIDTH      - 1 : 0] o_data1,  //! Register value 1 output
    output [DATA_WIDTH      - 1 : 0] o_data2,  //! Register value 2 output
    output [DATA_WIDTH      - 1 : 0] o_imm  ,  //! Immediate output
    output [NB_CTRL         - 1 : 0] o_ctrl ,  //! Control signals output
    output [NB_REGFILE_ADDR - 1 : 0] o_rs1  ,  //! Source Register 1 ID output
    output [NB_REGFILE_ADDR - 1 : 0] o_rs2  ,  //! Source Register 2 ID output
    output [NB_REGFILE_ADDR - 1 : 0] o_rd   ,  //! Destination Register ID output
    
    // Inputs
    input  [DATA_WIDTH      - 1 : 0] i_instr,  //! Instruction input
    input  [NB_PC           - 1 : 0] i_pc   ,  //! Program Counter input
    input  [DATA_WIDTH      - 1 : 0] i_data1,  //! Register value 1 input
    input  [DATA_WIDTH      - 1 : 0] i_data2,  //! Register value 2 input
    input  [DATA_WIDTH      - 1 : 0] i_imm  ,  //! Immediate input
    input  [NB_CTRL         - 1 : 0] i_ctrl ,  //! Control signals input
    input  [NB_REGFILE_ADDR - 1 : 0] i_rs1  ,  //! Source Register 1 ID input
    input  [NB_REGFILE_ADDR - 1 : 0] i_rs2  ,  //! Source Register 2 ID input
    input  [NB_REGFILE_ADDR - 1 : 0] i_rd   ,  //! Destination Register ID input
    input                            i_en   ,  //! Enable signal input
    input                            i_rst  ,  //! Reset signal
    input                            clk           //! Clock signal
);

    // Internal Signals
    reg [DATA_WIDTH      - 1 : 0] instr_reg;  //! Instruction register
    reg [NB_PC           - 1 : 0]  pc_reg  ;  //! Program Counter register
    reg [DATA_WIDTH      - 1 : 0] data1_reg;  //! Register value 1 register
    reg [DATA_WIDTH      - 1 : 0] data2_reg;  //! Register value 2 register
    reg [DATA_WIDTH      - 1 : 0] imm_reg  ;  //! Immediate register
    reg [NB_CTRL         - 1 : 0] ctrl_reg ;  //! Control signals register
    reg [NB_REGFILE_ADDR - 1 : 0] rs1_reg  ;  //! Source Register 1 ID register
    reg [NB_REGFILE_ADDR - 1 : 0] rs2_reg  ;  //! Source Register 2 ID register
    reg [NB_REGFILE_ADDR - 1 : 0] rd_reg   ;  //! Destination Register ID register

    // IF/EX Model
    always @(posedge clk) begin
        if (i_rst) begin
            instr_reg <= {DATA_WIDTH{1'b0}};
            pc_reg    <= {NB_PC{1'b0}};
            data1_reg <= {DATA_WIDTH{1'b0}};
            data2_reg <= {DATA_WIDTH{1'b0}};
            imm_reg   <= {DATA_WIDTH{1'b0}};
            ctrl_reg  <= {NB_CTRL{1'b0}};
            rs1_reg   <= {NB_REGFILE_ADDR{1'b0}};
            rs2_reg   <= {NB_REGFILE_ADDR{1'b0}};
            rd_reg    <= {NB_REGFILE_ADDR{1'b0}};
        end
        else if (i_en) begin
            instr_reg  <= i_instr;
            pc_reg     <= i_pc   ;
            data1_reg  <= i_data1;
            data2_reg  <= i_data2;
            imm_reg    <= i_imm  ;  
            ctrl_reg   <= i_ctrl ;
            rs1_reg    <= i_rs1  ;
            rs2_reg    <= i_rs2  ;
            rd_reg     <= i_rd   ;
        end
    end

    // Output Logic
    assign o_instr = instr_reg;
    assign o_pc    = pc_reg   ;
    assign o_data1 = data1_reg;
    assign o_data2 = data2_reg;
    assign o_imm   = imm_reg  ;
    assign o_ctrl  = ctrl_reg ;
    assign o_rs1   = rs1_reg  ;
    assign o_rs2   = rs2_reg  ;
    assign o_rd    = rd_reg   ;

endmodule