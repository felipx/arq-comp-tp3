//! @title EX/MEM REG
//! @file ex_mem_reg.v
//! @author Felipe Montero Bruni
//! @date 07-2024
//! @version 0.1

module ex_mem_reg
#(
    parameter NB_PC      = 32,
    parameter DATA_WIDTH = 32               //! NB of Data
) (
    // Outputs
    output reg                      o_regWrite   ,
    output reg                      o_memRead    ,
    output reg                      o_memWrite   ,
    output reg                      o_memToReg   ,
    output reg                      o_branch     ,
    output reg                      o_jump       ,
    output reg                      o_linkReg    ,
    output reg [1 : 0]              o_dataSize   ,
    output reg [NB_PC      - 1 : 0] o_pc_next    ,  //! PC+4 output
    output reg [NB_PC      - 1 : 0] o_branch_addr,
    output reg [DATA_WIDTH - 1 : 0] o_alu        ,  //! ALU result output
    output reg [DATA_WIDTH - 1 : 0] o_data2      ,  //! Data for store instructions output
    output reg [4 : 0]              o_rd_addr    ,
    output reg [2 : 0]              o_func3      ,
                                        
    // Inputs                           
    input wire                      i_regWrite   , 
    input wire                      i_memRead    , 
    input wire                      i_memWrite   , 
    input wire                      i_memToReg   , 
    input wire                      i_branch     ,
    input wire                      i_jump       ,
    input wire                      i_linkReg    ,
    input wire [1 : 0]              i_dataSize   , 
    input wire [NB_PC      - 1 : 0] i_pc_next    ,  //! PC+4 input
    input wire [NB_PC      - 1 : 0] i_branch_addr,
    input wire [DATA_WIDTH - 1 : 0] i_alu        ,  //! ALU result input
    input wire [DATA_WIDTH - 1 : 0] i_data2      ,  //! Data for store instructions input
    input wire [4 : 0]              i_rd_addr    ,
    input wire [2 : 0]              i_func3      ,
    input wire                      i_flush      ,
    input wire                      i_en         ,  //! Enable signal input
    input wire                      i_rst        ,
    input wire                      clk             //! Clock signal    
);

    //! IF/EX Register Model
    always @(posedge clk) begin
        if (i_rst | i_flush) begin
            o_regWrite    <= 1'b0              ;
            o_memRead     <= 1'b0              ;
            o_memWrite    <= 1'b0              ;
            o_memToReg    <= 1'b0              ;
            o_branch      <= 1'b0              ;
            o_jump        <= 1'b0              ;
            o_linkReg     <= 1'b0              ;
            o_dataSize    <= 2'b00             ;
            o_pc_next     <= {NB_PC{1'b0}}     ;
            o_branch_addr <= {NB_PC{1'b0}}     ;
            o_alu         <= {DATA_WIDTH{1'b0}};
            o_data2       <= {DATA_WIDTH{1'b0}};
            o_rd_addr     <= {5{1'b0}}         ;
            o_func3       <= {3{1'b0}}         ;
        end
        else if (i_en) begin
            o_regWrite    <= i_regWrite   ;
            o_memRead     <= i_memRead    ;
            o_memWrite    <= i_memWrite   ;
            o_memToReg    <= i_memToReg   ;
            o_branch      <= i_branch     ;
            o_jump        <= i_jump       ;
            o_linkReg     <= i_linkReg    ;
            o_dataSize    <= i_dataSize   ;
            o_pc_next     <= i_pc_next    ;
            o_branch_addr <= i_branch_addr;
            o_alu         <= i_alu        ;
            o_data2       <= i_data2      ;
            o_rd_addr     <= i_rd_addr    ;
            o_func3       <= i_func3      ;
        end
    end

endmodule