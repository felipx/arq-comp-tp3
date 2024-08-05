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
    output reg [NB_INSTR - 1 : 0] o_instr  ,  //! Instruction output
    output reg [NB_PC    - 1 : 0] o_pc     ,  //! Program Counter output
    output reg [NB_PC    - 1 : 0] o_pc_next,  //! Program Counter + 4 output
    
    // Inputs
    input  [NB_INSTR - 1 : 0] i_instr  ,  //! Instruction input
    input  [NB_PC    - 1 : 0] i_pc     ,  //! Program Counter input
    input  [NB_PC    - 1 : 0] i_pc_next,  //! Program Counter + 4 input
    input                     i_flush  ,  //! Branch flush signal input
    (* direct_enable = "true" *) input i_en,  //! Enable input
    input                     i_rst    ,  //! Reset input
    input                     clk         //! Clock input
);

    //! IF/ID Model
    always @(posedge clk) begin
        if (i_rst || i_flush) begin
            o_instr   <= {DATA_WIDTH{1'b0}};
            o_pc      <= {DATA_WIDTH{1'b0}};
            o_pc_next <= {DATA_WIDTH{1'b0}};
        end
        else if (i_en) begin
            o_instr   <= i_instr  ;
            o_pc      <= i_pc     ;
            o_pc_next <= i_pc_next;
        end
    end

endmodule