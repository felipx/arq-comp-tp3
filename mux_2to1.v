//! @title MUX_2TO1
//! @file mux_2to1.v
//! @author Felipe Montero Bruni
//! @date 07-2024
//! @version 0.1

module mux_2to1
#(
    parameter NB_MUX = 32                //! NB of Adder
) (
    output wire [NB_MUX - 1 : 0] o_mux,  //! Mux output
    input  wire [NB_MUX - 1 : 0] i_a  ,  //! First input
    input  wire [NB_MUX - 1 : 0] i_b  ,  //! Second input
    input  wire                  i_sel   //! Select signal
);

    //! Mux 2to1 Model
    assign o_mux = sel ? i_b : i_a;
    
endmodule