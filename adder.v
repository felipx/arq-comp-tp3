//! @title ADDER
//! @file adder.v
//! @author Felipe Montero Bruni
//! @date 07-2024
//! @version 0.1

module adder
#(
    parameter NB_ADDER = 32                //! NB of Adder
) (
    output wire [NB_ADDER - 1 : 0] o_sum,  //! Adder output
    input  wire [NB_ADDER - 1 : 0] i_a  ,  //! First input
    input  wire [NB_ADDER - 1 : 0] i_b  ,  //! Second input
);

    //! Output Logic
    assign o_sum = i_a + i_b;
    
endmodule