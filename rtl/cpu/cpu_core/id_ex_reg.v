//! @title ID/EX REG
//! @file id_ex_reg.v
//! @author Felipe Montero Bruni
//! @date 07-2024
//! @version 0.1

module id_ex_reg
#(
    parameter NB_PC      = 32,               //! NB of PC
    parameter DATA_WIDTH = 32,               //! NB of Data
    parameter NB_CTRL    = 12                //! NB of control signals 
) (
    // Outputs
    output reg                      o_regWrite,
    output reg                      o_memRead ,
    output reg                      o_memWrite,
    output reg                      o_ALUSrc  ,
    output reg                      o_memToReg,
    output reg                      o_branch  ,
    output reg                      o_jump    ,
    output reg                      o_linkReg ,
    output reg [1 : 0]              o_ALUOp   ,
    output reg [1 : 0]              o_dataSize,
    output reg [NB_PC      - 1 : 0] o_pc      ,  //! Program Counter output
    output reg [NB_PC      - 1 : 0] o_pc_next ,  //! Program Counter + 4 output
    output reg [DATA_WIDTH - 1 : 0] o_rs1_data,  //! Register 1 output
    output reg [DATA_WIDTH - 1 : 0] o_rs2_data,  //! Register 2 output
    output reg [DATA_WIDTH - 1 : 0] o_imm     ,  //! Immediate output
    output reg [6 : 0]              o_opcode  ,  //! Opcode output
    output reg [4 : 0]              o_rd_addr ,
    output reg [2 : 0]              o_func3   ,
    output reg [4 : 0]              o_rs1_addr,
    output reg [4 : 0]              o_rs2_addr,
    output reg [6 : 0]              o_func7   ,
                                                     
    // Inputs                           
    input wire [NB_CTRL    - 1 : 0] i_ctrl    ,  //! Control signals input
    input wire [NB_PC      - 1 : 0] i_pc      ,  //! Program Counter input
    input wire [NB_PC      - 1 : 0] i_pc_next ,  //! Program Counter + 4 input
    input wire [DATA_WIDTH - 1 : 0] i_rs1_data,  //! Register 1 input
    input wire [DATA_WIDTH - 1 : 0] i_rs2_data,  //! Register 2 input
    input wire [DATA_WIDTH - 1 : 0] i_imm     ,  //! Immediate input
    input wire [6 : 0]              i_opcode  ,
    input wire [4 : 0]              i_rd_addr ,
    input wire [2 : 0]              i_func3   ,
    input wire [4 : 0]              i_rs1_addr,
    input wire [4 : 0]              i_rs2_addr,
    input wire [6 : 0]              i_func7   ,
    input wire                      i_en      ,  //! Enable signal input
    input wire                      clk          //! Clock signal    
);

    //! IF/EX Register Model
    always @(posedge clk) begin
        if (i_en) begin
            o_regWrite <= i_ctrl[0]    ;
            o_memRead  <= i_ctrl[1]    ;
            o_memWrite <= i_ctrl[2]    ;
            o_ALUSrc   <= i_ctrl[3]    ;
            o_memToReg <= i_ctrl[4]    ;
            o_branch   <= i_ctrl[5]    ;
            o_jump     <= i_ctrl[6]    ;
            o_linkReg  <= i_ctrl[7]    ;
            o_ALUOp    <= i_ctrl[9 : 8];
            o_dataSize <= i_ctrl[11:10];
            o_pc       <= i_pc         ;
            o_pc_next  <= i_pc_next    ;
            o_rs1_data <= i_rs1_data   ;
            o_rs2_data <= i_rs2_data   ;
            o_imm      <= i_imm        ;
            o_opcode   <= i_opcode     ;
            o_rd_addr  <= i_rd_addr    ;
            o_func3    <= i_func3      ;
            o_rs1_addr <= i_rs1_addr   ;
            o_rs2_addr <= i_rs2_addr   ;
            o_func7    <= i_func7      ;
        end
    end

endmodule