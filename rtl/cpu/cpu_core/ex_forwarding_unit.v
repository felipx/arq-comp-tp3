//! @title EX FORWARDING UNIT
//! @file ex_forwarding_unit.v
//! @author Felipe Montero Bruni
//! @date 07-2024
//! @version 0.1

module ex_forwarding_unit
(
    // Outputs
    output reg [1 : 0] o_forward_a,     //! Forwarding control for source A
    output reg [1 : 0] o_forward_b,     //! Forwarding control for source B
                                      
    // Inputs                         
    input wire [4 : 0] i_ex_rs1      ,  //! Source register 1 ID from EX stage
    input wire [4 : 0] i_ex_rs2      ,  //! Source register 2 ID from EX stage
    input wire [4 : 0] i_mem_rd      ,  //! Destination register ID from MEM stage
    input wire [4 : 0] i_wb_rd       ,  //! Destination register ID from WB stage
    input wire         i_mem_RegWrite,  //! Register write signal from MEM stage
    input wire         i_wb_RegWrite    //! Register write signal from WB stage
);

    always @(*) begin
        // Default values (no forwarding)
        o_forward_a = 2'b00;
        o_forward_b = 2'b00;

        // Forwarding logic for source A
        if (i_mem_RegWrite && (i_mem_rd != 0) && (i_mem_rd == i_ex_rs1)) begin
            o_forward_a = 2'b10; // Forward from MEM stage
        end 
        else if (i_wb_RegWrite && (i_wb_rd != 0) && !(i_mem_RegWrite && (i_mem_rd != 0) && (i_mem_rd == i_ex_rs1)) && (i_wb_rd == i_ex_rs1)) begin
            o_forward_a = 2'b01; // Forward from WB stage
        end

        // Forwarding logic for source B
        if (i_mem_RegWrite && (i_mem_rd != 0) && (i_mem_rd == i_ex_rs2)) begin
            o_forward_b = 2'b10; // Forward from MEM stage
        end else if (i_wb_RegWrite && (i_wb_rd != 0) && !(i_mem_RegWrite && (i_mem_rd != 0) && (i_mem_rd == i_ex_rs2)) && (i_wb_rd == i_ex_rs2)) begin
            o_forward_b = 2'b01; // Forward from WB stage
        end
    end

endmodule
