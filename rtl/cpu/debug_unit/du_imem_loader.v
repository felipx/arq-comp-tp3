//! @title DEBUG UNIT INSTRUCTION MEMORY LOADER
//! @file du_imem_loader.v
//! @author Felipe Montero Bruni
//! @date 8-2024
//! @version 0.1

module du_imem_loader 
#(
    parameter NB_UART_DATA    = 8 ,
    parameter NB_REG          = 32,
    parameter NB_INSTRUCTION  = 32,  //! Size of instruction memory data
    parameter IMEM_ADDR_WIDTH = 8    //! Instruction Memory address width

) (
    // Outputs
    output reg                           o_done      ,
    output reg                           o_tx_start  ,  //! UART Tx start output
    output reg                           o_rd        ,  //! UART FIFO Rx read enable output
    output reg                           o_wr        ,  //! UART FIFO Tx write enable output
    output reg [NB_UART_DATA    - 1 : 0] o_wdata     ,  //! UART FIFO Tx write data
    output reg [NB_INSTRUCTION  - 1 : 0] o_imem_data ,
    output reg [IMEM_ADDR_WIDTH - 1 : 0] o_imem_waddr,
    output reg [1 : 0]                   o_imem_wsize,
    output reg                           o_imem_wen  ,

    // Inputs
    input wire                           i_start     ,
    input wire                           i_rx_done   ,
    input wire [NB_UART_DATA    - 1 : 0] i_rx_data   ,  //! UART FIFO Rx data input
    input wire                           i_rst       ,
    input wire                           clk            

);

    //! Local Parameters
    localparam NB_STATE       = 4;
    localparam NB_COUNTER     = 8;
    localparam NB_INSTR_COUNT = 4;

    localparam ACK  = 8'h05;
    localparam NAK  = 8'h15;
    localparam SOT  = 8'h01;
    localparam EOT  = 8'h04;

    //! Internal States
    localparam [NB_STATE - 1 : 0] IDLE         = 4'b0001;
    localparam [NB_STATE - 1 : 0] RECEIVE_FW_1 = 4'b0010;
    localparam [NB_STATE - 1 : 0] RECEIVE_FW_2 = 4'b0100;
    localparam [NB_STATE - 1 : 0] RECEIVE_FW_3 = 4'b1000;
    
    //! Internal Signals
    // State Register
    reg [NB_STATE - 1 : 0] state_reg ;
    reg [NB_STATE - 1 : 0] next_state;

    // Data Received Registers                         
    reg [NB_REG - 1 : 0] rx_data_reg ;
    reg [NB_REG - 1 : 0] rx_data_next;

    // Word's bytes Counter Registers  
    reg [NB_INSTR_COUNT - 1 : 0] data_count_reg ;
    reg [NB_INSTR_COUNT - 1 : 0] data_count_next;

    // IMEM Write Address Registers
    reg [IMEM_ADDR_WIDTH - 1 : 0] imem_addr_reg ;
    reg [IMEM_ADDR_WIDTH - 1 : 0] imem_addr_next;

    // Checksum Calc Registers
    reg [NB_UART_DATA - 1 : 0] cksum_reg ;
    reg [NB_UART_DATA - 1 : 0] cksum_next;

    // Write IMEM flag
    reg imem_write_reg;
    reg imem_write_next;

    // Data Counter Registers
    reg [NB_COUNTER - 1 : 0] counter_reg ;
    reg [NB_COUNTER - 1 : 0] counter_next;


    //! FSMD states and data registers
    always @(posedge clk) begin
        if (i_rst) begin
            state_reg      <= IDLE;
            rx_data_reg    <= {NB_REG{1'b0}};
            data_count_reg <= {NB_INSTR_COUNT{1'b0}};
            imem_addr_reg  <= {IMEM_ADDR_WIDTH{1'b0}};
            cksum_reg      <= {NB_UART_DATA{1'b0}};
            imem_write_reg <= 1'b1;
            counter_reg    <= {NB_COUNTER{1'b0}};
        end
        else begin
            state_reg      <= next_state;
            rx_data_reg    <= rx_data_next;
            data_count_reg <= data_count_next;
            imem_addr_reg  <= imem_addr_next;
            cksum_reg      <= cksum_next;
            imem_write_reg <= imem_write_next;
            counter_reg    <= counter_next;
        end
    end    

    //! Next-State Logic
    always @(*) begin
        // Default values
        next_state = state_reg;

        case (state_reg)
            IDLE: begin
                // Start receiving frame
                if (i_start) begin
                    next_state = RECEIVE_FW_1;
                end
            end

            RECEIVE_FW_1: begin
                if (i_rx_done) begin
                    if (counter_reg == 8'd1) begin
                        // If [blk #] = [~blk #] move to next state
                        if (i_rx_data == ~rx_data_reg[7:0]) begin
                            next_state = RECEIVE_FW_2;
                        end
                        else begin
                            next_state = IDLE;
                        end
                    end
                end
            end

            RECEIVE_FW_2: begin
                if (i_rx_done) begin
                    if ((counter_reg == 8'd128) && (cksum_reg == i_rx_data)) begin
                        next_state = RECEIVE_FW_3;  // No Error
                    end
                    else if ((counter_reg == 8'd128) && (cksum_reg != i_rx_data)) begin
                        next_state = IDLE;  // Error, reset FSM
                    end
                end
            end

            RECEIVE_FW_3: begin
                // If received byte is 0x01, new frame comming
                if (i_rx_data == SOT) begin
                    next_state = RECEIVE_FW_1;
                end
                // If received byte is EOT, FW receive complete
                if (i_rx_data == EOT) begin
                    next_state = IDLE;
                end
            end

            default: next_state = IDLE;
        endcase
    end

    //! State Logic
    always @(*) begin
        // Default Values
        o_done          = 1'b0;
        o_tx_start      = 1'b0;
        o_rd            = 1'b0;
        o_wr            = 1'b0;
        o_wdata         = 8'h00;
        o_imem_data     = {NB_INSTRUCTION{1'b0}};
        o_imem_waddr    = {IMEM_ADDR_WIDTH{1'b0}};
        o_imem_wsize    = 2'b00;
        o_imem_wen      = 1'b0;
        rx_data_next    = rx_data_reg;
        data_count_next = data_count_reg;
        imem_addr_next  = imem_addr_reg;
        cksum_next      = cksum_reg;
        imem_write_next = imem_write_reg;
        counter_next    = counter_reg;

        case (state_reg)
            RECEIVE_FW_1: begin
                // First byte received
                if (i_rx_done) begin
                    o_rd = 1'b1;
                    counter_next = counter_reg + 1'b1;

                    if (counter_reg == 8'd0) begin
                        rx_data_next[7:0] = i_rx_data; // store it in rx_data for future check against second byte
                    end
                    else if (counter_reg == 8'd1) begin
                        counter_next = {NB_COUNTER{1'b0}};
                    end
                end
            end
            
            RECEIVE_FW_2: begin
                // When a 32 bit instruction is complete, write into instruction memory
                if (data_count_reg == 3'b100 & imem_write_reg) begin
                    o_imem_data     = rx_data_reg;
                    o_imem_waddr    = imem_addr_reg;
                    o_imem_wsize    = 2'b11;
                    o_imem_wen      = 1'b1;
                    imem_addr_next  = imem_addr_reg + 3'd4;
                    data_count_next = {NB_INSTR_COUNT{1'b0}};

                    if (rx_data_reg == 32'h1A1A1A1A) begin
                        imem_write_next = 1'b0;
                    end
                end
                // Data received
                if (i_rx_done) begin
                    o_rd = 1;
                    counter_next = counter_reg + 1'b1;

                    // If end of frame
                    if (counter_reg == 8'd128) begin
                        // Send ACK if cksum OK
                        if (cksum_reg == i_rx_data) begin
                            o_wr           = 1;
                            o_wdata        = ACK;
                            o_tx_start     = 1'b1;
                            cksum_next     = {NB_UART_DATA{1'b0}};
                            imem_addr_next = {IMEM_ADDR_WIDTH{1'b0}};
                            counter_next   = {NB_COUNTER{1'b0}};
                        end
                        // Else send NAK  
                        else begin
                            o_wr           = 1;
                            o_wdata        = NAK;
                            o_tx_start     = 1'b1;
                            cksum_next     = {NB_UART_DATA{1'b0}};
                            imem_addr_next = {IMEM_ADDR_WIDTH{1'b0}};
                            counter_next   = {NB_COUNTER{1'b0}};
                        end
                    end
                    // Concatenate received data to form a 32 bit instruction
                    else begin
                        o_rd            = 1'b1;
                        rx_data_next    = {i_rx_data, rx_data_reg[NB_REG - 1 : NB_UART_DATA]};
                        data_count_next = data_count_reg + 1'b1;
                        cksum_next      = cksum_reg + i_rx_data;
                    end
                end
            end

            RECEIVE_FW_3: begin
                // If a byte is received, read it
                if (i_rx_done) begin
                    o_rd = 1'b1;
                    o_wr          = 1;
                    o_wdata       = ACK;
                    o_tx_start = 1'b1;
                end

                // If received byte is EOT, FW receive complete
                if (i_rx_data == EOT) begin
                    o_done = 1'b1;
                end
            end

            default: begin
                o_done = 1'b0;
                o_rd            = 1'b0;
                o_wr            = 1'b0;
                o_wdata         = 8'h00;
                o_imem_data     = {NB_INSTRUCTION{1'b0}};
                o_imem_waddr    = {IMEM_ADDR_WIDTH{1'b0}};
                o_imem_wsize    = 2'b00;
                o_imem_wen      = 1'b0;
                o_tx_start      = 1'b0;
                rx_data_next    = rx_data_reg;
                data_count_next = data_count_reg;
                imem_addr_next  = imem_addr_reg;
                cksum_next      = cksum_reg;
                imem_write_next = imem_write_reg;
                counter_next    = counter_reg;
            end
        endcase
    end
   
endmodule