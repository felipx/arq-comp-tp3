//! @title MEM/wB REG
//! @file mem_wb_reg.v
//! @author Felipe Montero Bruni
//! @date 07-2024
//! @version 0.1

module mem_wb_reg
#(
    parameter DATA_WIDTH = 32,           //! NB of Data
    parameter ADDR_WIDTH = 2             //! NB of MEM/WB reg address depth
    
) (
    // Outputs
    output [DATA_WIDTH - 1 : 0] o_ctrl,  //! Control signals output
    output [DATA_WIDTH - 1 : 0] o_data,  //! Data from memory output
    output [DATA_WIDTH - 1 : 0] o_alu ,  //! ALU result output
    output [DATA_WIDTH - 1 : 0] o_rd  ,  //! ID of Register to be written in the WB stage output
                                       
    // Inputs                          
    input  [DATA_WIDTH - 1 : 0] i_ctrl,  //! Control signals input
    input  [DATA_WIDTH - 1 : 0] i_data,  //! Data from memory input
    input  [DATA_WIDTH - 1 : 0] i_alu ,  //! ALU result input
    input  [DATA_WIDTH - 1 : 0] i_rd  ,  //! ID of Register to be written in the WB stage input
    input                       i_en  ,  //! Enable signal input
    input                       i_rst ,  //! Reset signal
    input                       clk      //! Clock signal    
);

    //! Local Parameters
    localparam DATA_DEPTH = 2**ADDR_WIDTH;                   // Depth of the register array

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
            reg_array[0] <= i_ctrl;
            reg_array[1] <= i_data;
            reg_array[2] <= i_alu ;
            reg_array[3] <= i_rd  ;
        end
    end

    // Output Logic
    assign o_ctrl = reg_array[0];
    assign o_data = reg_array[1];
    assign o_alu  = reg_Array[2];
    assign o_rd   = reg_Array[3];

endmodule