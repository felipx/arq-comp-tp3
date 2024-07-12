//! @title PC
//! @file pc.v
//! @author Felipe Montero Bruni
//! @date 07-2024
//! @version 0.1

module pc
#(
    parameter NB_PC = 32                //! NB of Program Counter
) (
    output wire [NB_PC - 1 : 0] o_pc ,  //! Program Counter output
    input  wire [NB_PC - 1 : 0] i_pc ,  //! Program Counter input
    input  wire                 i_en ,  //! Enable input
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
        else begin
            if (i_en)
                pc_reg <= i_pc;
            else
                pc_reg <= pc_reg;
        end
    end

    assign o_pc = pc_reg;
    
endmodule