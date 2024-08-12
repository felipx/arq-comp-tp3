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
    input wire         i_alu_result,  //! First bit of ALU result
    input wire         i_alu_zero  ,  //! ALU zero flag
    input wire         i_branch    ,  //! Branch instruction flag input
    input wire         i_jump      ,  //! JAL or JALR instruction flag input
    input wire         i_linkReg   ,  //! JALR instruction flag input
    input wire [2 : 0] i_func3     ,  //! Instruction func3 field
    input wire         clk
);
    
    // Func3 values for branch instructions
    localparam FUNC3_BEQ  = 3'b000;
    localparam FUNC3_BNE  = 3'b001;
    localparam FUNC3_BLT  = 3'b100;
    localparam FUNC3_BGE  = 3'b101;
    localparam FUNC3_BLTU = 3'b110;
    localparam FUNC3_BGEU = 3'b111;

    reg alu_result;
    reg alu_zero;
    reg branch;

    always @(posedge clk) begin
        alu_result <= i_alu_result;
        alu_zero   <= i_alu_zero;
        branch     <= i_branch;
    end

    always @(*) begin
        // Default values
        o_pcSrc = 2'b00;  // Default to PC + 4
        o_flush = 1'b0;   // Default to no flush

        if (branch) begin
            case (i_func3)
                FUNC3_BEQ : if ( alu_zero  ) o_pcSrc = 2'b01;  // BEQ taken if zero flag is set
                FUNC3_BNE : if (!alu_zero  ) o_pcSrc = 2'b01;  // BNE taken if zero flag is not set
                FUNC3_BLT : if ( alu_result) o_pcSrc = 2'b01;  // BLT taken if less than
                FUNC3_BGE : if (!alu_result) o_pcSrc = 2'b01;  // BGE taken if not less than
                FUNC3_BLTU: if ( alu_result) o_pcSrc = 2'b01;  // BLTU taken if less than unsigned
                FUNC3_BGEU: if (!alu_result) o_pcSrc = 2'b01;  // BGEU taken if not less than unsigned
                default   :                  o_pcSrc = 2'b00;
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

    //always @(*) begin
    //    // Default values
    //    o_pcSrc = 2'b00;  // Default to PC + 4
    //    o_flush = 1'b0;   // Default to no flush
//
    //    // Determine branch or jump type
    //    case (i_opcode)
    //        OPCODE_BRANCH: begin
    //            case (i_func3)
    //                FUNC3_BEQ : if (i_alu_zero)    o_pcSrc = 2'b01;  // BEQ taken if zero flag is set
    //                FUNC3_BNE : if (!i_alu_zero)   o_pcSrc = 2'b01;  // BNE taken if zero flag is not set
    //                FUNC3_BLT : if (i_alu_result)  o_pcSrc = 2'b01;  // BLT taken if less than
    //                FUNC3_BGE : if (!i_alu_result) o_pcSrc = 2'b01;  // BGE taken if not less than
    //                FUNC3_BLTU: if (i_alu_result)  o_pcSrc = 2'b01;  // BLTU taken if less than unsigned
    //                FUNC3_BGEU: if (!i_alu_result) o_pcSrc = 2'b01;  // BGEU taken if not less than unsigned
    //                default   :                    o_pcSrc = 2'b00;
    //            endcase
    //            if (o_pcSrc == 2'b01) o_flush = 1'b1;  // Flush if branch taken
    //        end
    //        OPCODE_JAL: begin
    //            o_pcSrc = 2'b01;  // JAL jump target (PC+Imm)
    //            o_flush = 1'b1;   // Flush pipeline
    //        end
    //        OPCODE_JALR: begin
    //            o_pcSrc = 2'b10;  // JALR jump target (rs1+Imm)
    //            o_flush = 1'b1;   // Flush pipeline
    //        end
    //        default: begin
    //            o_pcSrc = 2'b00;  // Default to PC + 4
    //            o_flush = 1'b0;   // Default to no flush
    //        end
    //         
    //    endcase
    //end

endmodule