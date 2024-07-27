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
    output [NB_INSTR - 1 : 0] o_instr  ,  //! Instruction output
    output [NB_PC    - 1 : 0] o_pc     ,  //! Program Counter output
    output [NB_PC    - 1 : 0] o_pc_next,  //! Program Counter + 4 output
    
    // Inputs
    input  [NB_INSTR - 1 : 0] i_instr  ,  //! Instruction input
    input  [NB_PC    - 1 : 0] i_pc     ,  //! Program Counter input
    input  [NB_PC    - 1 : 0] i_pc_next,  //! Program Counter + 4 input
    input                     i_flush  ,  //! Branch flush signal input
    input                     i_en     ,  //! Enable input
    input                     i_rst    ,  //! Reset input
    input                     clk         //! Clock input
);

    //! Local Parameters
    localparam DATA_WIDTH = 32;
    localparam DATA_DEPTH = 3 ;           // Depth of the register array

    //! Internal Signals
    reg [DATA_WIDTH - 1 : 0] reg_array [DATA_DEPTH - 1 : 0]; // Register array

    integer index;

    //! IF/ID Model
    always @(posedge clk) begin
        if (i_rst || i_flush) begin
            // Reset logic: Clear all register locations
            for (index = 0; index < DATA_DEPTH; index = index + 1) begin
                reg_array[index] <= {DATA_WIDTH{1'b0}};
            end
        end
        else if (i_en) begin
            reg_array[0] <= i_instr  ;
            reg_array[1] <= i_pc     ;
            reg_array[2] <= i_pc_next;
        end
    end

    // Output Logic
    assign o_instr   = reg_array[0];
    assign o_pc      = reg_array[1];
    assign o_pc_next = reg_array[2];

endmodule