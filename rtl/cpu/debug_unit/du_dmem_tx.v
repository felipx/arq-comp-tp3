

module du_dmem_tx 
#(
    parameter NB_DATA      = 32,
    parameter NB_UART_DATA = 8 
) (
    // Outputs
    output reg o_done,
    output reg o_rd  ,  //! UART FIFO Rx read enable output

    // Inputs
    input wire i_start  ,
    input wire i_rx_done,
    input wire i_rst    ,
    input wire clk       
);
    //! Local Parameters
    localparam NB_STATE   = 4;
    localparam NB_COUNTER = 3;

    //! Internal States
    localparam [NB_STATE - 1 : 0] IDLE    = 4'b0001;
    localparam [NB_STATE - 1 : 0] RECEIVE = 4'b0010;
    localparam [NB_STATE - 1 : 0] READ    = 4'b0100;
    localparam [NB_STATE - 1 : 0] SEND    = 4'b1000;

    //! Internal Signals
    // State Register
    reg [NB_STATE - 1 : 0] state_reg ;
    reg [NB_STATE - 1 : 0] next_state;

    // Data Received Registers                         
    reg [NB_REG - 1 : 0] rx_data_reg ;
    reg [NB_REG - 1 : 0] rx_data_next;

    // Data Memory Address Registers
    reg [4 : 0] dmem_addr_reg ;
    reg [4 : 0] dmem_addr_next;

    // Word's bytes counter registers
    reg [NB_COUNTER - 1 : 0] word_counter_reg ;
    reg [NB_COUNTER - 1 : 0] word_counter_next;


    //! FSMD states and data registers
    always @(posedge clk) begin
        if (i_rst) begin
            state_reg        <= IDLE;
            rx_data_reg      <= {NB_REG{1'b0}};
            dmem_addr_reg    <= {4{1'b0}};
            word_counter_reg <= {NB_COUNTER{1'b0}};
        end
        else begin
            state_reg        <= next_state;
            rx_data_reg      <= rx_data_next;
            dmem_addr_reg    <= dmem_addr_next;
            word_counter_reg <= word_counter_next;
        end
    end

    //! Next-State Logic
    always @(*) begin
        // Default values
        next_state = state_reg;

        case (state_reg)
            IDLE: begin
                if (i_start) begin
                    next_state = RECEIVE;
                end
            end
            RECEIVE: begin
                if (word_count_reg == 3'b100) begin
                    next_state = READ;
                end
            end
            READ: begin
                
            end
            SEND: begin
                
            end

            default: next_state = state_reg; 
        endcase
    end

    //! State Logic
    always @(*) begin
        // Default values
        o_done          = 1'b0;
        o_rd            = 1'b0;
        rx_data_next    = rx_data_reg;
        dmem_addr_next  = dmem_addr_reg;
        word_count_next = word_count_reg;

        case (state_reg)
            RECEIVE: begin
                if (i_rx_done) begin
                    o_rd         = 1'b1;
                    dmem_addr_next = {i_rx_data, dmem_addr_reg[NB_DATA - 1 : NB_UART_DATA]};
                    word_count_next = word_count_reg + 1'b1;
                end

                if (word_count_reg == 3'b100) begin
                    word_count_next = {NB_COUNTER{1'b0}};
                end
            end
            READ: begin
                
            end
            default: 
        endcase
    end


endmodule