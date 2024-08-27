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
    input wire [4              : 0] i_addr1 ,  //! Read register address 1
    input wire [4              : 0] i_addr2 ,  //! Read register address 2
    input wire [4              : 0] i_waddr1,  //! Write port 1 register address
    input wire [4              : 0] i_waddr2,  //! Write port 2 register address
    input wire [DATA_WIDTH - 1 : 0] i_wdata1,  //! Data input for write port 1
    input wire [DATA_WIDTH - 1 : 0] i_wdata2,  //! Data input for write port 2
    input wire                      i_wen1  ,  //! Write enable 1 signal
    input wire                      i_wen2  ,  //! Write enable 2 signal
    input wire                      i_rst   ,  //! Reset signal
    input wire                      clk        //! Clock signal
);

    //! Local Parameters
    localparam ADDR_WIDTH = 5            ;    //! Address width
    localparam DATA_DEPTH = 2**ADDR_WIDTH;    //! Regfile depth

    //! Register array
    reg [DATA_WIDTH - 1 : 0] reg_array [DATA_DEPTH - 1 : 0];
   
    integer i;

    //! Write Operation
    always @(negedge clk) begin
        // Initialize registers to zero on reset
        if (i_rst) begin
            for (i = 0; i < DATA_DEPTH; i = i + 1) begin
                reg_array[i] <= {DATA_WIDTH{1'b0}};
            end
        end
        else begin
            if (i_wen1) begin
                if (i_waddr1 != {ADDR_WIDTH{1'b0}}) begin  // Check if writing to x0 register
                    reg_array[i_waddr1] <= i_wdata1;
                end
            end
            if (i_wen2) begin
                if (i_waddr2 != {ADDR_WIDTH{1'b0}}) begin  // Check if writing to x0 register
                    reg_array[i_waddr2] <= i_wdata2;
                end
            end
        end
    end

    //! Read Port 1
    always @(*) begin
        o_dout1 = reg_array[i_addr1];

    end

    //! Read Port 2
    always @(*) begin
        o_dout2 = reg_array[i_addr2];
    end

endmodule