//! @title DEBUG UNIT MASTER CONTROLLER
//! @file du_master.v
//! @author Felipe Montero Bruni
//! @date 8-2024
//! @version 0.1

module du_master
#(
    parameter NB_INSTRUCTION = 32,  //! NB of IMEM data
    parameter NB_UART_DATA   = 8    //! NB of UART data
) (
    // Outputs
    output reg                        o_cpu_en         ,
    output reg                        o_load_start     ,
    output reg                        o_send_regs_start,
    output reg                        o_send_dmem_start,
    output reg                        o_tx_start       ,
    output reg                        o_rd             ,  //! UART FIFO Rx read enable output
    output reg                        o_wr             ,  //! UART FIFO Tx write enable output
    output reg [NB_UART_DATA - 1 : 0] o_wdata          ,  //! UART FIFO Tx write data
    output reg                        o_rst            ,
    
    // Inputs
    input wire                          i_loader_done   ,
    input wire                          i_send_regs_done,
    input wire                          i_send_dmem_done,
    input wire [NB_INSTRUCTION - 1 : 0] i_instr         ,
    input wire [NB_UART_DATA   - 1 : 0] i_rx_data       ,  //! UART FIFO Rx data input
    input wire                          i_rx_done       ,
    input wire                          i_rst           ,
    input wire                          clk             
);
    
    //! Local Parameters
    localparam NB_STATE   = 8 ;
    localparam NB_COUNTER = 32;

    localparam ACK  = 8'h05;
    localparam NAK  = 8'h15;
    localparam SOT  = 8'h01;
    localparam EOT  = 8'h04;

    localparam CONT = 8'h01;
    localparam STEP = 8'h02;

    localparam COUNTER_TICKS = 32'd199_999_999;

    //! Internal States
    localparam [NB_STATE - 1 : 0] IDLE         = 8'b00000001;  // 0x01
    localparam [NB_STATE - 1 : 0] RECEIVE_FW   = 8'b00000010;  // 0x02
    localparam [NB_STATE - 1 : 0] MODE_SELECT  = 8'b00000100;  // 0x04
    localparam [NB_STATE - 1 : 0] CONT_MODE    = 8'b00001000;  // 0x08
    localparam [NB_STATE - 1 : 0] STEP_MODE    = 8'b00010000;  // 0x10
    localparam [NB_STATE - 1 : 0] SEND_REGS    = 8'b00100000;  // 0x20
    localparam [NB_STATE - 1 : 0] SEND_DMEM    = 8'b01000000;  // 0x40
    localparam [NB_STATE - 1 : 0] STOP         = 8'b10000000;  // 0x80
    
    
    //! Internal Signals
    // State Register
    reg [NB_STATE - 1 : 0] state_reg ;
    reg [NB_STATE - 1 : 0] next_state;

    // Internal Counter Registers
    reg [NB_COUNTER - 1 : 0] counter_reg;
    reg [NB_COUNTER - 1 : 0] counter_next;

    reg         step_mode_reg    ;
    reg         step_mode_next   ;
    reg [2 : 0] step_counter_reg ;
    reg [2 : 0] step_counter_next;
    reg         stop_flag_reg    ;
    reg         stop_flag_next   ;
    reg [2 : 0] stop_counter_reg ;
    reg [2 : 0] stop_counter_next;


    //! FSMD states and data registers
    always @(posedge clk) begin
        if (i_rst) begin
            state_reg        <= IDLE;
            counter_reg      <= {NB_COUNTER{1'b0}};
            step_mode_reg    <= 1'b0;
            step_counter_reg <= 1'b0;
            stop_flag_reg    <= 1'b0;
            stop_counter_reg <= {3{1'b0}};
        end
        else begin
            state_reg        <= next_state;
            counter_reg      <= counter_next;
            step_mode_reg    <= step_mode_next;
            step_counter_reg <= step_counter_next;
            stop_flag_reg    <= stop_flag_next;   
            stop_counter_reg <= stop_counter_next;
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
                    next_state = RECEIVE_FW;
                end
            end

            RECEIVE_FW: begin
                if (i_loader_done) begin
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
                if (stop_counter_reg == 2'b01) begin
                   next_state = SEND_REGS; 
                end
            end

            STEP_MODE: begin
                if (stop_counter_reg == 3'b100) begin
                    next_state = STOP;
                end
                else if (step_counter_reg == 3'b011) begin
                    next_state = SEND_REGS;
                end
            end

            SEND_REGS: begin
                if (i_send_regs_done) begin
                    next_state = SEND_DMEM;
                end
            end

            SEND_DMEM: begin
                if (i_send_dmem_done && ~step_mode_reg) begin
                    next_state = STOP;
                end
                else if (i_send_dmem_done && step_mode_reg) begin
                    next_state = STEP_MODE;
                end
            end

            STOP: begin
                // If 0x01 is received go to IDLE
                if (stop_counter_reg == 3'b100) begin
                    next_state = IDLE;
                end
            end

            default: next_state = IDLE;
        endcase
    end
    
    //! State Logic
    always @(*) begin
        // Default values
        o_cpu_en          = 1'b0;
        o_load_start      = 1'b0;
        o_send_regs_start = 1'b0;
        o_send_dmem_start = 1'b0;
        o_rd              = 1'b0;
        o_wr              = 1'b0;
        o_wdata           = 8'h00;
        o_tx_start        = 1'b0;
        o_rst             = 1'b0;
        counter_next      = counter_reg;
        step_mode_next    = step_mode_reg;
        step_counter_next = step_counter_reg;
        stop_flag_next    = stop_flag_reg;
        stop_counter_next = stop_counter_reg;
        
        case (state_reg)
            IDLE: begin
                counter_next = counter_reg + 1'b1;

                // Sends NAK every (1/f)*COUNTER_TICKS secs
                if (counter_reg == COUNTER_TICKS) begin
                    o_wr         = 1;
                    o_wdata      = NAK;
                    o_tx_start   = 1'b1;
                    counter_next = {NB_COUNTER{1'b0}};
                end
                
                // If a byte is received, read it
                if (i_rx_done) begin
                    o_rd = 1'b1;
                end
            end
            
            RECEIVE_FW: begin
                o_load_start = 1'b1;
            end
            
            MODE_SELECT: begin
                counter_next = counter_reg + 1'b1;

                // Sends '*' every (1/f)*COUNTER_TICKS secs
                if (counter_reg == COUNTER_TICKS) begin
                    o_wr         = 1;
                    o_wdata      = 8'h2A;
                    o_tx_start   = 1'b1;
                    counter_next = {NB_COUNTER{1'b0}};
                end

                if (i_rx_done) begin
                    o_rd = 1'b1;

                    if (i_rx_data == STEP) begin
                        step_mode_next = step_mode_reg + 1'b1;
                    end
                    else if (i_rx_data == CONT) begin
                        step_mode_next = 1'b0;
                    end
                end
            end
            
            CONT_MODE: begin
                o_cpu_en     = 1'b1;

                if (i_instr == 32'h1A1A1A1A) begin
                   stop_flag_next = 1'b1; 
                end

                if (stop_flag_reg) begin
                    stop_counter_next = stop_counter_reg + 1'b1;
                end

                if (stop_counter_reg == 2'b01) begin
                   stop_counter_next = {3{1'b0}};
                   stop_flag_next    = 1'b0;
                end
            end

            STEP_MODE: begin
                if (step_counter_reg == 3'b000) begin
                    o_cpu_en = 1'b1;
                    step_counter_next = step_counter_reg + 1'b1;
                end
                else if (step_counter_reg != 3'b000) begin
                    o_cpu_en = 1'b0;
                    step_counter_next = step_counter_reg + 1'b1;

                    if (step_counter_reg == 3'b011) begin
                        step_counter_next = 3'b000;

                        if (stop_flag_reg) begin
                            stop_counter_next = stop_counter_reg + 1'b1;
                        end
                    end
                end

                if (i_instr == 32'h1A1A1A1A) begin
                   stop_flag_next = 1'b1; 
                end

                if (stop_counter_reg == 3'b100) begin
                   stop_counter_next = {3{1'b0}};
                   stop_flag_next    = 1'b0;
                end
            end
            
            SEND_REGS: begin
                o_send_regs_start = 1'b1;
            end

            SEND_DMEM: begin
                o_send_dmem_start = 1'b1;
            end

            STOP: begin
                counter_next = counter_reg + 1'b1;

                // Sends '0' every (1/f)*COUNTER_TICKS secs
                if (counter_reg == COUNTER_TICKS) begin
                    o_wr         = 1;
                    o_wdata      = 8'h30;
                    o_tx_start   = 1'b1;
                    counter_next = {NB_COUNTER{1'b0}};
                end

                if (i_rx_done) begin
                    o_rd = 1'b1;
                
                    if (i_rx_data == 8'h01) begin
                        o_rst = 1'b1;
                        stop_counter_next = stop_counter_reg + 1'b1;
                    end
                end

                if (stop_counter_reg != 3'b000) begin
                    stop_counter_next = stop_counter_reg + 1'b1;
                end

                if (stop_counter_reg == 3'b100) begin
                    stop_counter_next = 3'b000;
                end
            end
            
            default: begin
                o_cpu_en          = 1'b0;
                o_load_start      = 1'b0;
                o_send_regs_start = 1'b0;
                o_send_dmem_start = 1'b0;
                o_rd              = 1'b0;
                o_wr              = 1'b0;
                o_wdata           = 8'h00;
                o_tx_start        = 1'b0;
                counter_next      = counter_reg;
                step_mode_next    = step_mode_reg;
                step_counter_next = step_counter_reg;
                stop_flag_next    = stop_flag_reg;
                stop_counter_next = stop_counter_reg;
            end 
        endcase
    end

endmodule