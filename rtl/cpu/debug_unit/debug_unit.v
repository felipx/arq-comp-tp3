
module debug_unit
#(
    parameter NB_PC           = 32,  //! NB of Program Counter
    parameter NB_REG          = 32,
    parameter NB_DMEM_DATA    = 32,
    parameter NB_UART_DATA    = 8 ,
    parameter NB_UART_ADDR    = 5 ,  //! NB of UART fifo's regs depth
    parameter NB_INSTRUCTION  = 32,  //! Size of instruction memory data
    parameter IMEM_ADDR_WIDTH = 8    //! Instruction Memory address width
) (
    // Outputs
    output reg                           o_cpu_en    ,
    output reg                           o_tx_start  ,
    output reg                           o_rd        ,  //! FIFO Rx read enable output
    output reg                           o_wr        ,  //! FIFO Tx write enable output
    output reg [NB_UART_DATA    - 1 : 0] o_wdata     ,  //! FIFO Tx write data
    output reg [NB_UART_ADDR    - 1 : 0] o_wsize     ,
    output reg [NB_INSTRUCTION  - 1 : 0] o_imem_data ,
    output reg [IMEM_ADDR_WIDTH - 1 : 0] o_imem_waddr,
    output reg [1 : 0]                   o_imem_wsize,
    output reg                           o_imem_wen  ,
    
    // Inputs
    input wire [NB_PC        - 1 : 0] i_pc          ,  //! PC input
    input wire [NB_REG       - 1 : 0] i_regfile_data,  //! CPU's register file input
    input wire [NB_DMEM_DATA - 1 : 0] i_dmem_data   ,  //! CPU'd DMEM data input
    input wire [NB_UART_DATA - 1 : 0] i_rx_data     ,  //! FIFO Rx data input
    input wire                        i_rx_done     ,
    input wire                        i_tx_done     ,
    input wire                        i_rst         ,
    input wire                        clk           
);
    
    localparam NB_STATE       = 9 ;
    localparam NB_COUNTER     = 32;
    localparam NB_INSTR_COUNT = 4 ;

    localparam ACK  = 8'h05;
    localparam NAK  = 8'h15;
    localparam SOT  = 8'h01;
    localparam EOT  = 8'h04;

    localparam CONT = 8'h01;
    localparam STEP = 8'h02;

    localparam [NB_STATE - 1 : 0] IDLE         = 9'b000000001;
    localparam [NB_STATE - 1 : 0] RECEIVE_FW_1 = 9'b000000010;
    localparam [NB_STATE - 1 : 0] RECEIVE_FW_2 = 9'b000000100;
    localparam [NB_STATE - 1 : 0] RECEIVE_FW_3 = 9'b000001000;
    localparam [NB_STATE - 1 : 0] MODE_SELECT  = 9'b000010000;
    localparam [NB_STATE - 1 : 0] CONT_MODE    = 9'b000100000;
    localparam [NB_STATE - 1 : 0] STEP_MODE    = 9'b001000000;
    localparam [NB_STATE - 1 : 0] SEND_REGS    = 9'b010000000;
    localparam [NB_STATE - 1 : 0] SEND_DMEM    = 9'b100000000;
    
    
    //! Internal Signals
    // State Register
    reg [NB_STATE - 1 : 0] state_reg ;
    reg [NB_STATE - 1 : 0] next_state;

    // Data Received Registers                         
    reg [NB_REG - 1 : 0] rx_data_reg ;
    reg [NB_REG - 1 : 0] rx_data_next;
                                              
    // Data Counter Registers  
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

    // Internal Counter Register
    reg [NB_COUNTER     - 1 : 0] counter_reg;

    //assign o_tx_start = tx_start_reg;


    //! FSMD states and data registers
    always @(posedge clk) begin
        if (i_rst) begin
            state_reg      <= IDLE;
            rx_data_reg    <= {NB_REG{1'b0}};
            data_count_reg <= {NB_INSTR_COUNT{1'b0}};
            imem_addr_reg  <= {IMEM_ADDR_WIDTH{1'b0}};
            cksum_reg      <= {NB_UART_DATA{1'b0}};
            imem_write_reg <= 1'b1;
            //tx_start_reg   <= 1'b0;
        end
        else begin
            state_reg      <= next_state;
            rx_data_reg    <= rx_data_next;
            data_count_reg <= data_count_next;
            imem_addr_reg  <= imem_addr_next;
            cksum_reg      <= cksum_next;
            imem_write_reg <= imem_write_next;
            //tx_start_reg   <= tx_start_next;
        end
    end


    //! Next-State Logic
    always @(*) begin
        // Default values
        next_state = state_reg;

        case (state_reg)
            IDLE: begin
                // Start receiving frame
                if (i_rx_data == SOT) begin
                    next_state = RECEIVE_FW_1;
                end
            end

            RECEIVE_FW_1: begin
                if (i_rx_done) begin
                    if (counter_reg == 32'd1) begin
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
                    if ((counter_reg == 32'd128) && (cksum_reg == i_rx_data)) begin
                        next_state = RECEIVE_FW_3;  // No Error
                    end
                    else if ((counter_reg == 32'd128) && (cksum_reg != i_rx_data)) begin
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
                    next_state = MODE_SELECT;
                end
            end

            MODE_SELECT: begin
                if (i_rx_done) begin
                    // If 0x01 is received go to continuous mode
                    if (i_rx_data == CONT) begin
                        next_state = CONT_MODE;
                    end
                    // If 0x02 is received go to step mode
                    else if (i_rx_data == STEP) begin
                        next_state = STEP_MODE;
                    end
                end
            end

            CONT_MODE: begin
                if (i_pc == 32'h1A1A1A1A) begin
                   next_state = SEND_REGS; 
                end
            end

            STEP_MODE: begin
                next_state = STEP_MODE;
            end

            SEND_REGS: begin
                next_state = SEND_REGS;
            end

            SEND_DMEM: begin
                next_state = SEND_DMEM;
            end

            default: next_state = IDLE;
        endcase
    end

    //! State Logic
    always @(*) begin
        // Default values
        o_cpu_en        = 1'b0;
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
        //tx_start_next   = 1'b0;
        
        case (state_reg)
            IDLE: begin
                // Sends NAK every 4 secs
                if (counter_reg == 32'd399_999_999) begin
                    o_wr = 1;
                    o_wdata = NAK;
                    //tx_start_next = 1'b1;
                    o_tx_start = 1'b1;
                end
                
                // If a byte is received, read it
                if (i_rx_done) begin
                    o_rd = 1'b1;
                end
            end
            
            RECEIVE_FW_1: begin
                // First byte received
                if (i_rx_done) begin
                    o_rd = 1'b1;

                    if (counter_reg == 32'd0) begin
                        rx_data_next[7:0] = i_rx_data; // store it in rx_data for future check against second byte
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
                    // If end of frame
                    if (counter_reg == 32'd128) begin
                        // Send ACK if cksum OK
                        if (cksum_reg == i_rx_data) begin
                            o_wr           = 1;
                            o_wdata        = ACK;
                            //tx_start_next  = 1'b1;
                            o_tx_start = 1'b1;
                            cksum_next     = {NB_UART_DATA{1'b0}};
                            imem_addr_next = {IMEM_ADDR_WIDTH{1'b0}};
                        end
                        // Else send NAK  
                        else begin
                            o_wr           = 1;
                            o_wdata        = NAK;
                            //tx_start_next  = 1'b1;
                            o_tx_start = 1'b1;
                            cksum_next     = {NB_UART_DATA{1'b0}};
                            imem_addr_next = {IMEM_ADDR_WIDTH{1'b0}};
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
                    //tx_start_next = 1'b1;
                    o_tx_start = 1'b1;
                end
            end

            MODE_SELECT: begin
                // Sends '*' every 4 secs
                if (counter_reg == 32'd399_999_999) begin
                    o_wr = 1;
                    o_wdata = 8'h2A;
                    //tx_start_next = 1'b1;
                    o_tx_start = 1'b1;
                end
            end

            CONT_MODE: begin
                o_cpu_en = 1'b1;
            end

            SEND_REGS: begin
                
            end
            
            //default: 
        endcase
    end
    
    
    //////////////////////////////////////////////////////////////////
    // Internal Counter                                             //
    // On IDLE and MODE_SELECT is used to count 4 secs between NAKs //
    // On RECEIVE_FW_x states is used to count received data        //
    //////////////////////////////////////////////////////////////////
    
    // Counter logic
    always @(posedge clk) begin
        if (i_rst) begin
            counter_reg <= 32'd0;
        end 
        else begin
            if (state_reg == IDLE && next_state == RECEIVE_FW_1) begin
                counter_reg <= 32'd0; // Reset counter on IDLE->RECEIVE_FW_1 transition
            end
            else if (state_reg == RECEIVE_FW_1 && next_state == IDLE) begin
                counter_reg <= 32'd0; // Reset counter on RECEIVE_FW_1=>IDLE transition
            end
            else if (state_reg == RECEIVE_FW_1 && next_state == RECEIVE_FW_2) begin
                counter_reg <= 32'd0; // Reset counter on RECEIVE_FW_1=>RECEIVE_FW_2 transition
            end
            else if (state_reg == RECEIVE_FW_2 && next_state == RECEIVE_FW_3) begin
                counter_reg <= 32'd0; // Reset counter on RECEIVE_FW_2=>RECEIVE_FW_3 transition
            end
            else if (state_reg == MODE_SELECT && next_state == CONT_MODE) begin
                counter_reg <= 32'd0; // Reset counter on MODE_SELECT=>CONT_MODE transition
            end
            else if (state_reg == MODE_SELECT && next_state == STEP_MODE) begin
                counter_reg <= 32'd0; // Reset counter on MODE_SELECT=>STEP_MODE transition
            end
            else begin
                case (state_reg)
                    IDLE: begin
                        // On IDLE, the counter is used to send NAK every 4 secs
                        if (counter_reg == 32'd399_999_999) begin
                            counter_reg <= 32'd0;
                        end 
                        else begin
                            counter_reg <= counter_reg + 1;
                        end
                    end
                    
                    RECEIVE_FW_1, RECEIVE_FW_2: begin
                        // On RECEIVE_FW_1/2, the counter is used to count received data
                        if (i_rx_done) begin
                            counter_reg <= counter_reg + 1;
                        end
                    end

                    MODE_SELECT: begin
                        // On MODE_SELECT, the counter is used to send '*' every 4 secs
                        if (counter_reg == 32'd399_999_999) begin
                            counter_reg <= 32'd0;
                        end 
                        else begin
                            counter_reg <= counter_reg + 1;
                        end
                    end
                    
                    default: counter_reg <= 32'd0;
                endcase
            end
        end
    end


endmodule