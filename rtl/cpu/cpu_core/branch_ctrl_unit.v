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
    output reg [1 : 0] o_pcSrc ,      //! PC source control signal
    output reg         o_flush ,      //! Pipeline flush signal
    
    // Inputs
    input wire [NB_DATA - 1 : 0] i_alu_result,  //! First bit of ALU result
    input wire                   i_branch    ,  //! Branch instruction flag input
    input wire                   i_jump      ,  //! JAL or JALR instruction flag input
    input wire                   i_linkReg   ,  //! JALR instruction flag input
    input wire                   i_func3_0   ,  //! Instruction func3 field
    input wire                   i_func3_2      //! Instruction func3 field
);
    
    // Func3 values for branch instructions
    localparam FUNC3_BEQ  = 3'b000;
    localparam FUNC3_BNE  = 3'b001;
    localparam FUNC3_BLT  = 3'b100;
    localparam FUNC3_BGE  = 3'b101;
    localparam FUNC3_BLTU = 3'b110;
    localparam FUNC3_BGEU = 3'b111;

    always @(*) begin
        // Default values
        o_pcSrc = 2'b00;  // Default to PC + 4
        o_flush = 1'b0;   // Default to no flush

        if (i_branch) begin
            case (i_func3_2)
                1'b0: begin
                    if (i_func3_0 == 1'b0 && (i_alu_result == {NB_DATA{1'b0}}))       o_pcSrc = 2'b01;  // BEQ taken if zero flag is set
                    else if (i_func3_0 == 1'b1 && !(i_alu_result == {NB_DATA{1'b0}})) o_pcSrc = 2'b01;  // BEQ taken if zero flag is set
                end
                1'b1: begin
                    if (i_func3_0 == 1'b0 && i_alu_result[0])       o_pcSrc = 2'b01;  // BLT/BLTU taken if less than
                    else if (i_func3_0 == 1'b1 && ~i_alu_result[0]) o_pcSrc = 2'b01;  // BGE/BGEU taken if less than unsigned
                end 
            endcase
            if (o_pcSrc == 2'b01) o_flush = 1'b1;  // Flush if branch taken
        end
        else if (i_jump && ~i_linkReg) begin
            o_pcSrc = 2'b01;  // JAL jump target (PC+Imm)
            o_flush = 1'b1;   // Flush pipeline
        end
        else if (i_jump && i_linkReg) begin
            o_pcSrc = 2'b10;  // JALR jump target (rs1+Imm)
            o_flush = 1'b1;   // Flush pipeline
        end
    end

endmodule