module jump_hazard_detection_unit
(
    // Outputs
    output reg       o_write_en   ,  //! Control signal to write to PC and IF/ID reg

    // Inputs
    input wire [6:0] i_opcode     ,  //! Opcode input
    input wire       i_ex_regWrite,  //! RegWrite signal from EX stage
    input wire [4:0] i_ex_rd      ,  //! Destination register addr from EX stage
    input wire [4:0] i_id_rs1     ,  //! Source register 1 addr from ID stage
    input wire [4:0] i_id_rs2     ,  //! Source register 2 addr from ID stage
    input wire       clk
);

    localparam I_TYPE_3 = 7'b1100111;  //! Opcode for JARL instruction
    localparam B_TYPE   = 7'b1100011;  //! Opcode for B-Type branch instructions

    reg not_stall;

    always @(*) begin
        // Default values (no hazard)
        o_write_en = 1'b1;

        // RegWrite hazard detection
        if (i_opcode == I_TYPE_3) begin
            if (i_ex_regWrite && (i_ex_rd == i_id_rs1) && not_stall) begin
                o_write_en = 1'b0;    // Stall PC and IF/ID
            end
        end

        if (i_opcode == B_TYPE) begin
            if (i_ex_regWrite && ((i_ex_rd == i_id_rs1) || (i_ex_rd == i_id_rs2)) && not_stall) begin
                o_write_en = 1'b0;    // Stall PC and IF/ID
            end
        end
    end

    always @(posedge clk) begin
        not_stall <= o_write_en;
    end

endmodule