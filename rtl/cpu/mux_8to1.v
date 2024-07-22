//! @title 3:1 MULTIPLEXOR
//! @file mux_3to1.v
//! @author Felipe Montero Bruni
//! @date 07-2024
//! @version 0.1

module mux_3to1
#(
    parameter NB_MUX = 32                  //! NB of data
) (
    // Output
    output reg [DATA_WIDTH-1:0] o_data ,   //! Data output
                                       
    // Inputs                           
    input      [DATA_WIDTH-1:0] i_data0,   //! Input data 0
    input      [DATA_WIDTH-1:0] i_data1,   //! Input data 1
    input      [DATA_WIDTH-1:0] i_data2,   //! Input data 2
    input      [DATA_WIDTH-1:0] i_data3,   //! Input data 3
    input      [DATA_WIDTH-1:0] i_data4,   //! Input data 4
    input      [DATA_WIDTH-1:0] i_data5,   //! Input data 5
    input      [DATA_WIDTH-1:0] i_data6,   //! Input data 6
    input      [DATA_WIDTH-1:0] i_data7,   //! Input data 7
    input      [3:0]            i_sel      //! Select signal
);

    always @(*) begin
        case (i_sel)
            3'b000  : o_data = i_data0;    //! Select input data 0
            3'b001  : o_data = i_data1;    //! Select input data 1
            3'b010  : o_data = i_data2;    //! Select input data 2
            3'b011  : o_data = i_data3;    //! Select input data 3
            3'b100  : o_data = i_data4;    //! Select input data 4
            3'b101  : o_data = i_data5;    //! Select input data 5
            3'b110  : o_data = i_data6;    //! Select input data 6
            3'b111  : o_data = i_data7;    //! Select input data 7
        endcase
    end

endmodule