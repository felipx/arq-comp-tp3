//! @title MEM/wB REG
//! @file mem_wb_reg.v
//! @author Felipe Montero Bruni
//! @date 07-2024
//! @version 0.1

module mem_wb_reg
#(
    parameter DATA_WIDTH = 32               //! NB of Data
) (
    // Outputs
    output [DATA_WIDTH - 1 : 0] o_ctrl   ,  //! Control signals output
    output [DATA_WIDTH - 1 : 0] o_pc_next,  //! PC+4 output
    output [DATA_WIDTH - 1 : 0] o_data   ,  //! Data from memory output
    output [DATA_WIDTH - 1 : 0] o_alu    ,  //! ALU result output
    output [DATA_WIDTH - 1 : 0] o_instr  ,  //! Instruction output
                                       
    // Inputs                          
    input  [DATA_WIDTH - 1 : 0] i_ctrl   ,  //! Control signals input
    output [DATA_WIDTH - 1 : 0] i_pc_next,  //! PC+4 input
    input  [DATA_WIDTH - 1 : 0] i_data   ,  //! Data from memory input
    input  [DATA_WIDTH - 1 : 0] i_alu    ,  //! ALU result input
    input  [DATA_WIDTH - 1 : 0] i_instr  ,  //! Instruction input
    input                       i_en     ,  //! Enable signal input
    input                       i_rst    ,  //! Reset signal
    input                       clk         //! Clock signal    
);

    //! Local Parameters
    localparam DATA_DEPTH = 5;              //! Depth of the register array

    //! Internal Signals
    reg [DATA_WIDTH - 1 : 0] reg_array [DATA_DEPTH - 1 : 0]; // Register array

    integer index;

    // IF/EX Register Model
    always @(posedge clk) begin
        if (i_rst) begin
            // Reset logic: Clear all register locations
            for (index = 0; index < DATA_DEPTH; index = index + 1) begin
                reg_array[index] <= {DATA_WIDTH{1'b0}};
            end
        end
        else if (i_en) begin
            reg_array[0] <= i_ctrl   ;
            reg_array[1] <= i_pc_next;
            reg_array[2] <= i_data   ;
            reg_array[3] <= i_alu    ;
            reg_array[4] <= i_instr  ;
        end
    end

    // Output Logic
    assign o_ctrl    = reg_array[0];
    assign o_pc_next = reg_array[1];
    assign o_data    = reg_array[2];
    assign o_alu     = reg_array[3];
    assign o_instr   = reg_array[4];

endmodule