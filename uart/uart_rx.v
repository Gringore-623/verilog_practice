module uart_rx  (

    input clk,
    input rst_n,
    input rx,
    output reg [7:0] rx_data,
    output reg rx_valid,
    output reg framing_error;

);

parameter   IDLE  = 2'd0,
            START  = 2'd1,
            DATA = 2'd2,
            STOP  = 2'd3;

reg rx_meta, rx_sync; //CDC

reg [7:0] rx_shift_reg; //store output data
reg [2:0] bit_cnt;
reg [1:0] state, next_state;
reg [8:0] baud_cnt;

wire baud_tick, half_baud_tick;

assign  baud_tick = (baud_cnt == 9'd433);
assign  half_baud_tick = (baud_cnt == 8'd216);
//assign  tx_done = (state == STOP) && (baud_tick);
//assign  rx_valid = (state == IDLE);

always @(*) begin
    next_state = state;

    case (state) 

        IDLE: begin
            if (rx_sync == 1'b0) begin
                next_state = START;    
            end
        end

        START: begin
            
            if (half_baud_tick) begin
                if (!rx_sync) begin
                    next_state = DATA;
                end
                else
                    next_state = IDLE;
            end;
                
        end

        DATA: begin
            if (bit_cnt == 7 && baud_tick) begin

                next_state = STOP;
                
            end
        end

        STOP: begin
            if (baud_tick) begin
                next_state = IDLE;
            end
        end
    endcase
end

//CDC
always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin
        rx_meta <= 1'b1;
        rx_sync <= 1'b1;
    end

    else begin
        rx_meta <= rx;
        rx_sync <= rx_meta;
    end
    
end

//state register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
    end
    else 
        state <= next_state;
end

//data path
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin

        baud_cnt      <= 0;
        bit_cnt       <= 0;
        rx_shift_reg  <= 0;
        rx_valid      <= 0;
        framing_error <= 0;
    end

    else begin

        //latch TX data
        //if (state == IDLE && tx_valid && tx_ready) begin
            //tx_shift_reg <= tx_data;
        //end

        // pulse 默认拉低
        rx_valid      <= 0;
        framing_error <= 0;

        //baud counter
        if (state == IDLE) begin
            baud_cnt <= 8'b0;
        end

        else if(state == START) begin
            
            if (half_baud_tick) begin
                baud_cnt <= 0;
            end
            else
                baud_cnt <= baud_cnt + 1;   
        end

        else begin

            if (baud_tick)
                baud_cnt <= 9'b0;
            else
                baud_cnt <= baud_cnt + 1;

        end
        
        //bit counter
        if(state != DATA)
            bit_cnt <= 0;
            
        else begin
              
            if (baud_tick) begin

                if (bit_cnt < 7) begin
                    bit_cnt <= bit_cnt + 1;
                end

                else begin
                    bit_cnt <= 0;
                end
            end 
        end

        //receive RX data
        if (state == DATA && baud_tick) begin
            rx_shift_reg[bit_cnt] <= rx_sync;
        end

        //STOP
        if (state == STOP && baud_tick) begin

            if (rx_sync) begin
                rx_data <= rx_shift_reg;
                rx_valid <= 1'b1;
            end
            else
                framing_error <= 1;
        end
    end
end

endmodule