//! @title DATA MEMORY CONTROL UNIT
//! @file data_mem_ctrl_unit.v
//! @author Felipe Montero Bruni
//! @date 07-2024
//! @version 0.1

module data_mem_ctrl_unit
#(
    parameter DATA_WIDTH = 32
) (
    // Outputs
    output reg [DATA_WIDTH - 1 : 0] o_data,
    output reg [1 : 0]              o_size,

    // Inputs
    input wire [DATA_WIDTH - 1 : 0] i_data  ,
    input wire [6 : 0]              i_opcode,
    input wire [2 : 0]              i_func3 
);
    
    //! Size Output Logic
    always @(*) begin
        // Default size output
        o_size = 2'b00;

        case (i_func3)
            3'b000:  o_size = 2'b01;  // LB, SB
            3'b001:  o_size = 2'b10;  // LH, SH
            3'b010:  o_size = 2'b11;  // LW, SW
            3'b100:  o_size = 2'b01;  // LBU
            3'b101:  o_size = 2'b10;  // LHU
            default: o_size = 2'b00;
        endcase
    end

    //! Data Output Logic
    always @(*) begin
        // Default data output
        o_data = {DATA_WIDTH{1'b0}};

        if (i_opcode ==7'b0000011) begin  // Load instructions
            case (i_func3)
                3'b000:  o_data = {{24{i_data[7]}}, i_data[7:0]};    // LB
                3'b001:  o_data = {{16{i_data[15]}}, i_data[15:0]};  // LH
                3'b010:  o_data = i_data;                            // LW
                3'b100:  o_data = {24'b0, i_data[7:0]};              // LBU
                3'b101:  o_data = {16'b0, i_data[15:0]};             // LHU
                default: o_data = {DATA_WIDTH{1'b0}};
            endcase
        end
    end

endmodule