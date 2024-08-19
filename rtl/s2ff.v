//! @title 2-FLIP-FLOP SYNCHRONIZER 
//! @file s2ff.v
//! @author Felipe Montero Bruni
//! @date 10-2023
//! @version 0.1

module s2ff
(
    // Output
    output wire sync_out,   //! Synchronized output signal
    
    // Inputs
    input wire async_in,    //! Asynchronous input signal
    input wire clk          //! Clock signal input
);

    //! Internal signals
    reg sync_ff1;
    reg sync_ff2;

    always @(posedge clk) begin
        // sync_ff1 captures the asynchronous input signal
        sync_ff1 <= async_in;
        // sync_ff2 captures the output of the first flip-flop
        sync_ff2 <= sync_ff1;
    end

    assign sync_out = sync_ff2;

endmodule