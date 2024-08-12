//! @title DATA MEMORY OUTPUT UNIT
//! @file data_mem_output_unit.v
//! @author Felipe Montero Bruni
//! @date 07-2024
//! @version 0.1

module data_mem_output_unit
#(
    parameter DATA_WIDTH = 32
) (
    // Outputs
    output reg [DATA_WIDTH - 1 : 0] o_data,

    // Inputs
    input wire [DATA_WIDTH - 1 : 0] i_data ,
    input wire [2 : 0]              i_func3 
);
    
    //! Data Output Logic
    always @(*) begin
        // Default data output
        o_data = {DATA_WIDTH{1'b0}};

        case (i_func3)
            3'b000:  o_data = {{24{i_data[7]}}, i_data[7:0]};    // LB
            3'b001:  o_data = {{16{i_data[15]}}, i_data[15:0]};  // LH
            3'b010:  o_data = i_data;                            // LW
            3'b100:  o_data = {24'b0, i_data[7:0]};              // LBU
            3'b101:  o_data = {16'b0, i_data[15:0]};             // LHU
            default: o_data = {DATA_WIDTH{1'b0}};
        endcase
    end

endmodule