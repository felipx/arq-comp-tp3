//! @title MEM FORWARDING UNIT
//! @file mem_forwarding_unit.v
//! @author Felipe Montero Bruni
//! @date 07-2024
//! @version 0.1

module mem_forwarding_unit 
#(
    
) (
    // Outputs
    output reg [1:0] o_forward_b,     //! Forwarding control for source B

    // Inputs
    input wire [4:0] i_mem_rs2,       //! Source register 2 from MEM stage
    input wire [4:0] i_wb_rd,         //! Destination register from WB stage
    input wire       i_wb_RegWrite    //! Register write signal from WB stage
);

    always @(*) begin
        // Default value (no forwarding)
        o_forward_b = 2'b00;

        // Forwarding logic for store data
        if (i_wb_RegWrite && (i_wb_rd != 0) && (i_wb_rd == i_mem_rs2)) begin
            o_forward_b = 2'b01; // Forward from WB stage
        end
    end

endmodule