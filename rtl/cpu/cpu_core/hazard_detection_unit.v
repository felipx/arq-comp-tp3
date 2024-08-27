//! @title HAZARD DETECTION UNIT
//! @file hazard_detection_unit.v
//! @author Felipe Montero Bruni
//! @date 07-2024
//! @version 0.1

module hazard_detection_unit
(
    // Outputs
    output reg       o_write_en   ,     //! PC and IF/ID write enable control signal 
    output reg       o_control_mux,     //! Control signal for control unit mux 

    // Inputs
    input wire       i_id_ex_mem_read,  //! MemRead signal from ID/EX stage
    input wire [4:0] i_id_ex_rd      ,  //! Destination register ID from ID/EX stage
    input wire [4:0] i_if_id_rs1     ,  //! Source register 1 ID from IF/ID stage
    input wire [4:0] i_if_id_rs2        //! Source register 2 ID from IF/ID stage
);

    always @(*) begin
        // Default values (no hazard)
        o_write_en = 1'b1;
        o_control_mux = 1'b0;

        // Load-use hazard detection
        if (i_id_ex_mem_read && ((i_id_ex_rd == i_if_id_rs1) || (i_id_ex_rd == i_if_id_rs2))) begin
            o_write_en = 1'b0;    // Stall PC and IF/ID
            o_control_mux = 1'b1; // Insert NOP
        end
    end

endmodule