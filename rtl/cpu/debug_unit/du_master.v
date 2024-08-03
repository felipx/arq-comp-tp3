//! @title DEBUG UNIT MASTER CONTROLLER
//! @file du_master.v
//! @author Felipe Montero Bruni
//! @date 8-2024
//! @version 0.1

module du_master
#(
    parameter NB_PC        = 32,  //! NB of Program Counter
    parameter NB_UART_DATA = 8    //! NB of UART data
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
    
    // Inputs
    input wire                        i_loader_done   ,
    input wire                        i_send_regs_done,
    input wire                        i_send_dmem_done,
    input wire [NB_PC        - 1 : 0] i_pc            ,  //! PC input
    input wire [NB_UART_DATA - 1 : 0] i_rx_data       ,  //! UART FIFO Rx data input
    input wire                        i_rx_done       ,
    input wire                        i_tx_done       ,
    input wire                        i_rst           ,
    input wire                        clk             
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

    //! Internal States
    localparam [NB_STATE - 1 : 0] IDLE         = 8'b00000001;
    localparam [NB_STATE - 1 : 0] RECEIVE_FW   = 8'b00000010;
    localparam [NB_STATE - 1 : 0] MODE_SELECT  = 8'b00000100;
    localparam [NB_STATE - 1 : 0] CONT_MODE    = 8'b00001000;
    localparam [NB_STATE - 1 : 0] STEP_MODE    = 8'b00010000;
    localparam [NB_STATE - 1 : 0] SEND_REGS    = 8'b00100000;
    localparam [NB_STATE - 1 : 0] SEND_DMEM    = 8'b01000000;
    localparam [NB_STATE - 1 : 0] STOP         = 8'b10000000;
    
    
    //! Internal Signals
    // State Register
    reg [NB_STATE - 1 : 0] state_reg ;
    reg [NB_STATE - 1 : 0] next_state;

    // Internal Counter Register
    reg [NB_COUNTER     - 1 : 0] counter_reg;


    //! FSMD states and data registers
    always @(posedge clk) begin
        if (i_rst) begin
            state_reg <= IDLE;
        end
        else begin
            state_reg <= next_state;
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
                if (i_pc == 32'h1A1A1A1A) begin
                   next_state = SEND_REGS; 
                end
            end

            STEP_MODE: begin
                next_state = STEP_MODE;
            end

            SEND_REGS: begin
                if (i_send_regs_done) begin
                    next_state = SEND_DMEM;
                end
            end

            SEND_DMEM: begin
                if (i_send_dmem_done) begin
                    next_state = STOP;
                end
            end

            STOP: next_state = STOP;

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
        
        case (state_reg)
            IDLE: begin
                // Sends NAK every 4 secs
                if (counter_reg == 32'd399_999_999) begin
                    o_wr = 1;
                    o_wdata = NAK;
                    o_tx_start = 1'b1;
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
                // Sends '*' every 4 secs
                if (counter_reg == 32'd399_999_999) begin
                    o_wr = 1;
                    o_wdata = 8'h2A;
                    o_tx_start = 1'b1;
                end
            end
            
            CONT_MODE: begin
                o_cpu_en = 1'b1;
            end
            
            SEND_REGS: begin
                o_send_regs_start = 1'b1;
            end

            SEND_DMEM: begin
                o_send_dmem_start = 1'b1;
            end
            
            //default: 
        endcase
    end
    
    
    //TODO: REMOVE, no longer needed
    
    // Counter logic
    always @(posedge clk) begin
        if (i_rst) begin
            counter_reg <= 32'd0;
        end 
        else begin
            if (state_reg == IDLE && next_state == RECEIVE_FW) begin
                counter_reg <= 32'd0; // Reset counter on IDLE->RECEIVE_FW transition
            end
            else if (state_reg == RECEIVE_FW && next_state == MODE_SELECT) begin
                counter_reg <= 32'd0; // Reset counter on RECEIVE_FW_1=>IDLE transition
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