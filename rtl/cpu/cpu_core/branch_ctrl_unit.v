//! @title BRANCH CONTROL UNIT
//! @file branch_ctrl_unit.v
//! @author Felipe Montero Bruni
//! @date 07-2024
//! @version 0.1

module branch_ctrl_unit
#(
    parameter NB_DATA = 32
) (
    // Outputs
    output reg o_pcSrc,                        //! PC source control signal
    output reg o_flush,                        //! Pipeline flush signal
    
    // Inputs
    input wire [NB_DATA - 1 : 0] i_rs1_data,
    input wire [NB_DATA - 1 : 0] i_rs2_data,
    input wire [6 : 0]           i_opcode  ,
    input wire [2 : 0]           i_func3   ,    //! Instruction func3 field
    input wire                   i_stall   ,
    input wire                   clk
);
    
    localparam B_TYPE = 7'b1100011;  //! Opcode for B-Type branch instructions

    reg [NB_DATA - 1 : 0] result;
    reg [NB_DATA - 1 : 0] rs1_data;
    reg [NB_DATA - 1 : 0] rs2_data;

    always @(negedge clk) begin
        rs1_data <= i_rs1_data;
        rs2_data <= i_rs2_data;
    end

    always @(*) begin
        // Default values
        o_pcSrc = 1'b0;   // Default to PC + 4
        o_flush = 1'b0;   // Default to no flush

        if (~i_stall) begin
            if (i_opcode == B_TYPE) begin
                case (i_func3[2])
                    1'b0: begin
                        if (i_func3[0] == 1'b0 && (result == {NB_DATA{1'b0}}))       o_pcSrc = 1'b1;  // BEQ taken if zero flag is set
                        else if (i_func3[0] == 1'b1 && !(result == {NB_DATA{1'b0}})) o_pcSrc = 1'b1;  // BEQ taken if zero flag is not set
                    end
                    1'b1: begin
                        if (i_func3[0] == 1'b0 && result[0])       o_pcSrc = 1'b1;  // BLT/BLTU taken if less than
                        else if (i_func3[0] == 1'b1 && ~result[0]) o_pcSrc = 1'b1;  // BGE/BGEU taken if less than unsigned
                    end 
                endcase
                if (o_pcSrc == 1'b1) o_flush = 1'b1;  // Flush if branch taken
            end
        end
    end

    always @(*) begin
        result = {NB_DATA{1'b0}};
        
        if (i_func3[2] == 1'b0) begin
            result = rs1_data - rs2_data;
        end
        else if (i_func3[2:1] == 2'b10) begin
            result = ($signed(rs1_data) < $signed(rs2_data)) ? 1 : 0;
        end
        else if (i_func3[2:1] == 2'b11) begin
            result = (rs1_data < rs2_data) ? 1 : 0;
        end
    end

endmodule