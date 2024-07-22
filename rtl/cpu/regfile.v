//! @title IF/ID REG
//! @file if_id_reg.v
//! @author Felipe Montero Bruni
//! @date 07-2024
//! @version 0.1

module regfile
#(
    parameter DATA_WIDTH = 32                 //! Size of each memory location 
) (
    // Outputs
    output reg [DATA_WIDTH - 1 : 0] o_dout1,  //! Data output for read port 1
    output reg [DATA_WIDTH - 1 : 0] o_dout2,  //! Data output for read port 2
    
    // Inputs
    input      [ADDR_WIDTH - 1 : 0] i_addr1,  //! Read register address 1
    input      [ADDR_WIDTH - 1 : 0] i_addr2,  //! Read register address 2
    input      [ADDR_WIDTH - 1 : 0] i_waddr,  //! Write register address
    input      [DATA_WIDTH - 1 : 0] i_wdata,  //! Data input for write port
    input                           i_wen  ,  //! Write enable signal
    input                           i_rst  ,  //! Reset signal
    input                           clk       //! Clock signal
);

    //! Local Parameters
    localparam ADDR_WIDTH = 5            ;    //! Address width
    localparam DATA_DEPTH = 2**ADDR_WIDTH;    //! Regfile depth

    //! Register array
    reg [DATA_WIDTH-1:0] reg_array [0 : DATA_DEPTH - 1];

    //! Initialize registers to zero on reset
    integer i;
    always @(posedge clk) begin
        if (i_rst) begin
            for (i = 0; i < DATA_DEPTH; i = i + 1) begin
                reg_array[i] <= {DATA_WIDTH{1'b0}};
            end
        end
    end

    //! Write Operation
    always @(posedge clk) begin
        if (i_wen && !i_rst) begin
            if (i_waddr != {ADDR_WIDTH{1'b0}}) begin  // Check if writing to x0 register
                reg_array[i_waddr] <= i_wdata;
            end
        end
    end

    //! Read Port 1
    always @(*) begin
        if (i_addr1 == {DATA_DEPTH{1'b0}}) begin
            o_dout1 = {DATA_WIDTH{1'b0}};           // x0 register is hardwired to zero
        end else begin
            o_dout1 = reg_array[i_addr1];
        end
    end

    //! Read Port 2
    always @(*) begin
        if (i_addr2 == {DATA_DEPTH{1'b0}}) begin
            o_dout2 = {DATA_WIDTH{1'b0}};           // x0 register is hardwired to zero
        end else begin
            o_dout2 = reg_array[i_addr2];
        end
    end

endmodule