

module du_dmem_tx 
#(
    parameter NB_DATA         = 32,
    parameter NB_UART_DATA    = 8 
) (
    // Outputs
    output reg                        o_done      ,
    output reg                        o_dmem_rd   ,
    output reg [1 : 0]                o_dmem_rsize,
    output reg [NB_DATA      - 1 : 0] o_dmem_raddr,
    output reg                        o_rd        ,  //! UART FIFO Rx read enable output
    output reg                        o_wr        ,  //! UART FIFO Tx write enable output
    output reg                        o_tx_start  ,  //! UART Tx start output
    output reg [NB_UART_DATA - 1 : 0] o_wdata     ,  //! UART FIFO Tx write data

    // Inputs
    input wire                        i_start    ,
    input wire [NB_DATA      - 1 : 0] i_dmem_data,
    input wire                        i_rx_done  ,
    input wire [NB_UART_DATA - 1 : 0] i_rx_data  ,  //! UART FIFO Rx data input
    input wire                        i_tx_done  ,
    input wire                        i_rst      ,
    input wire                        clk         
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
    reg [NB_DATA - 1 : 0] rx_data_reg ;
    reg [NB_DATA - 1 : 0] rx_data_next;

    // Data Memory Address Registers
    reg [NB_DATA - 1 : 0] dmem_addr_reg ;
    reg [NB_DATA - 1 : 0] dmem_addr_next;

    // Word's bytes counter registers
    reg [NB_COUNTER - 1 : 0] word_counter_reg ;
    reg [NB_COUNTER - 1 : 0] word_counter_next;


    //! FSMD states and data registers
    always @(posedge clk) begin
        if (i_rst) begin
            state_reg        <= IDLE;
            rx_data_reg      <= {NB_DATA{1'b0}};
            dmem_addr_reg    <= {NB_DATA{1'b0}};
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
                if (word_counter_reg == 3'b100) begin
                    if (dmem_addr_reg == 32'hFFFF_FFFF) begin
                        next_state = IDLE;
                    end
                    else begin
                        next_state = READ;
                    end
                end
            end
            READ: begin
                //if (o_dmem_rd) begin
                if (word_counter_reg == 1'b1) begin
                    next_state = SEND;
                end
            end
            SEND: begin
                if (word_counter_reg == 3'b100 && i_tx_done) begin
                    next_state = RECEIVE;
                end
            end

            default: next_state = state_reg; 
        endcase
    end

    //! State Logic
    always @(*) begin
        // Default values
        o_done          = 1'b0;
        o_rd            = 1'b0;
        o_wr            = 1'b0;
        o_tx_start      = 1'b0;
        o_wdata         = 8'h00;
        o_dmem_rd       = 1'b0;
        o_dmem_rsize    = 2'b00;
        o_dmem_raddr    = {NB_DATA{1'b0}};
        rx_data_next    = rx_data_reg;
        dmem_addr_next  = dmem_addr_reg;
        word_counter_next = word_counter_reg;

        case (state_reg)
            RECEIVE: begin
                rx_data_next = {NB_DATA{1'b0}};
                if (i_rx_done) begin
                    o_rd           = 1'b1;
                    dmem_addr_next = {i_rx_data, dmem_addr_reg[NB_DATA - 1 : NB_UART_DATA]};
                    word_counter_next = word_counter_reg + 1'b1;
                end

                if (word_counter_reg == 3'b100) begin
                    word_counter_next = {NB_COUNTER{1'b0}};
                    if (dmem_addr_reg == 32'hFFFF_FFFF) begin
                        o_done = 1'b1;
                    end
                end
            end
            READ: begin
                o_dmem_rd    = 1'b1;
                o_dmem_rsize = 2'b11;
                o_dmem_raddr = dmem_addr_reg;
                
                word_counter_next = word_counter_reg + 1'b1;

                if (word_counter_reg == 1'b1) begin
                    word_counter_next = {NB_COUNTER{1'b0}};
                    rx_data_next = i_dmem_data;
                end
            end
            SEND: begin
                if (word_counter_reg == 3'b100) begin
                    if (i_tx_done) begin
                        word_counter_next = {NB_COUNTER{1'b0}};
                    end
                end
                else if (word_counter_reg == 3'b000) begin
                    o_wdata           = rx_data_reg[7 : 0];
                    o_wr              = 1'b1;
                    o_tx_start        = 1'b1;
                    word_counter_next = word_counter_reg + 1'b1;
                end
                else if (word_counter_reg == 3'b001) begin
                    if (i_tx_done) begin
                        o_wdata           = rx_data_reg[15 : 8];
                        o_wr              = 1'b1;
                        o_tx_start        = 1'b1;
                        word_counter_next = word_counter_reg + 1'b1;
                    end
                end
                else if (word_counter_reg == 3'b010) begin
                    if (i_tx_done) begin
                        o_wdata           = rx_data_reg[23 : 16];
                        o_wr              = 1'b1;
                        o_tx_start        = 1'b1;
                        word_counter_next = word_counter_reg + 1'b1;
                    end
                end
                else if (word_counter_reg == 3'b011) begin
                    if (i_tx_done) begin
                        o_wdata           = rx_data_reg[31 : 24];
                        o_wr              = 1'b1;
                        o_tx_start        = 1'b1;
                        word_counter_next = word_counter_reg + 1'b1;
                    end
                end
            end
            default: begin
                o_done          = 1'b0;
                o_rd            = 1'b0;
                o_wr            = 1'b0;
                o_tx_start      = 1'b0;
                o_wdata         = 8'h00;
                o_dmem_rd       = 1'b0;
                o_dmem_rsize    = 2'b00;
                o_dmem_raddr    = {NB_DATA{1'b0}};
                rx_data_next    = rx_data_reg;
                dmem_addr_next  = dmem_addr_reg;
                word_counter_next = word_counter_reg;
            end
        endcase
    end


endmodule