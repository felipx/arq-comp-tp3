module hazard_detection_unit (
    input wire       i_id_ex_mem_read,  // MemRead signal from ID/EX stage
    input wire [4:0] i_id_ex_rd,        // Destination register from ID/EX stage
    input wire [4:0] i_if_id_rs1,       // Source register 1 from IF/ID stage
    input wire [4:0] i_if_id_rs2,       // Source register 2 from IF/ID stage
    output reg       o_pc_write,        // Control signal to write to PC
    output reg       o_if_id_write,     // Control signal to write to IF/ID register
    output reg       o_control_mux      // Control signal for control unit mux
);

    always @(*) begin
        // Default values (no hazard)
        o_pc_write = 1'b1;
        o_if_id_write = 1'b1;
        o_control_mux = 1'b0;

        // Load-use hazard detection
        if (i_id_ex_mem_read && 
           ((i_id_ex_rd == i_if_id_rs1) || (i_id_ex_rd == i_if_id_rs2))) begin
            o_pc_write = 1'b0;    // Stall PC
            o_if_id_write = 1'b0; // Stall IF/ID
            o_control_mux = 1'b1; // Insert NOP
        end
    end

endmodule