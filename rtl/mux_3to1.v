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
    input      [1:0]            i_sel      //! Select signal
);

    always @(*) begin
        case (i_sel)
            2'b00: o_data   = i_data0;            //! Select input data 0
            2'b01: o_data   = i_data1;            //! Select input data 1
            2'b02: o_data   = i_data2;            //! Select input data 2
            default: o_data = {DATA_WIDTH{1'b0}}; //! Default case (should not happen)
        endcase
    end

endmodule