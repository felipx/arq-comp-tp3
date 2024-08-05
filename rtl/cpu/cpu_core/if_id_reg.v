//! @title IF/ID REG
//! @file if_id_reg.v
//! @author Felipe Montero Bruni
//! @date 07-2024
//! @version 0.1

module if_id_reg
#(
    parameter NB_INSTR = 32,              //! Instruction width
    parameter NB_PC    = 32               //! Program Counter width
) (
    // Outputs
    output reg [NB_PC    - 1 : 0] o_pc      ,  //! Program Counter output
    output reg [NB_PC    - 1 : 0] o_pc_next ,  //! Program Counter + 4 output
    output reg [NB_INSTR - 1 : 0] o_instr   ,  //! Instruction output
    output reg [6 : 0]            o_opcode  ,
    output reg [4 : 0]            o_rd_add  ,
    output reg [2 : 0]            o_func3   ,
    output reg [4 : 0]            o_rs1_addr,
    output reg [4 : 0]            o_rs2_addr,
    output reg [6 : 0]            o_func7   ,
    
    // Inputs
    input wire [NB_INSTR - 1 : 0] i_instr  ,  //! Instruction input
    input wire [NB_PC    - 1 : 0] i_pc     ,  //! Program Counter input
    input wire [NB_PC    - 1 : 0] i_pc_next,  //! Program Counter + 4 input
    input wire                    i_flush  ,  //! Branch flush signal input
    input wire                    i_en     ,  //! Enable input
    input wire                    i_rst    ,  //! Reset input
    input wire                    clk         //! Clock input
);

    //! IF/ID Model
    always @(posedge clk) begin
        if (i_rst || i_flush) begin
            o_pc      <= {NB_PC{1'b0}};
            o_pc_next <= {NB_PC{1'b0}};
            o_instr   <= {NB_INSTR{1'b0}};
            o_opcode  <= {7{1'b0}};
            o_rd_add  <= {5{1'b0}};
            o_func3   <= {3{1'b0}};
            o_rs1_addr<= {5{1'b0}};
            o_rs2_addr<= {5{1'b0}};
            o_func7   <= {7{1'b0}};
        end
        else if (i_en) begin
            o_pc      <= i_pc            ;
            o_pc_next <= i_pc_next       ;
            o_instr   <= i_instr         ;
            o_opcode  <= i_instr[6  :  0];
            o_rd_add  <= i_instr[11 :  7];
            o_func3   <= i_instr[14 : 12];
            o_rs1_addr<= i_instr[19 : 15];
            o_rs2_addr<= i_instr[24 : 20];
            o_func7   <= i_instr[31 : 25];
        end
    end

endmodule