//! @title PC
//! @file pc.v
//! @author Felipe Montero Bruni
//! @date 07-2024
//! @version 0.1

module pc
#(
    parameter NB_PC = 32                //! NB of Program Counter
) (
    // Output
    output wire [NB_PC - 1 : 0] o_pc ,  //! Program Counter output
    
    // Inputs
    input  wire [NB_PC - 1 : 0] i_pc ,  //! Program Counter input
    (* direct_enable = "true" *) input  wire                 i_en ,  //! Enable input
    input  wire                 i_rst,  //! Reset
    input  wire                 clk     //! Clock
);

    //! Internal Signals
    reg [NB_PC - 1 : 0] pc_reg;  //! Program Counter Reg

    //! Program Counter Model
    always @(posedge clk) begin
        if (i_rst) begin
            pc_reg <= {NB_PC{1'b0}};
        end
        else if (i_en) begin
            pc_reg <= i_pc;
        end
    end

    assign o_pc = pc_reg;
    
endmodule