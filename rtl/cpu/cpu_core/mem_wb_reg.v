//! @title MEM/wB REG
//! @file mem_wb_reg.v
//! @author Felipe Montero Bruni
//! @date 07-2024
//! @version 0.1

module mem_wb_reg
#(
    parameter NB_PC      = 32,
    parameter DATA_WIDTH = 32               //! NB of Data
) (
    // Outputs
    output reg                      o_regWrite,
    output reg                      o_memToReg,
    output reg                      o_jump    ,
    output reg [NB_PC      - 1 : 0] o_pc_next ,  //! PC+4 output
    output reg [DATA_WIDTH - 1 : 0] o_data    ,  //! Data from memory output
    output reg [DATA_WIDTH - 1 : 0] o_alu     ,  //! ALU result output
    output reg [4 : 0]              o_rd_addr ,
                                       
    // Inputs                          
    input wire                      i_regWrite,
    input wire                      i_memToReg,
    input wire                      i_jump    ,
    input wire [NB_PC      - 1 : 0] i_pc_next ,  //! PC+4 input
    input wire [DATA_WIDTH - 1 : 0] i_data    ,  //! Data from memory input
    input wire [DATA_WIDTH - 1 : 0] i_alu     ,  //! ALU result input
    input wire [4 : 0]              i_rd_addr ,
    input wire                      i_en      ,  //! Enable signal input
    input wire                      clk          //! Clock signal    
);

    //! IF/EX Register Model
    always @(posedge clk) begin
        if (i_en) begin
            o_regWrite <= i_regWrite;
            o_memToReg <= i_memToReg;
            o_jump     <= i_jump    ;
            o_pc_next  <= i_pc_next ;
            o_data     <= i_data    ;
            o_alu      <= i_alu     ;
            o_rd_addr  <= i_rd_addr ;
        end
    end

endmodule