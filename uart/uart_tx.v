module uart_tx  (

    input clk,
    input rst_n,
    input tx_valid,
    input [7:0] tx_data,
    output tx_ready,
    output tx,
    output tx_done

);

parameter   IDLE  = 2'd0,
            START  = 2'd1,
            SEND = 2'd2,
            STOP  = 2'd3;


reg [7:0] tx_shift_reg;
reg [2:0] bit_cnt;
reg [1:0] state, next_state;
reg [8:0] baud_cnt;

wire baud_tick;
assign  baud_tick = (baud_cnt == 9'd433);
assign  tx_done = (state == STOP) && (baud_tick);
assign  tx_ready = (state == IDLE);

always @(*) begin
    next_state = state;

    case (state) 

        IDLE: begin
            if (tx_valid && tx_ready) begin
                next_state = START;
                
            end
        end

        START: begin
            
            if (baud_tick) begin
                next_state = SEND;   
            end;
                
        end

        SEND: begin
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

        baud_cnt <= 9'b0;
        bit_cnt  <= 3'b0;
        tx_shift_reg <= 8'b0;

    end

    else begin

        //latch TX data
        if (state == IDLE && tx_valid && tx_ready) begin
            tx_shift_reg <= tx_data;
        end

        //baud counter
        if (state == IDLE) begin
            baud_cnt <=3'b0;
        end

        else begin
            if (baud_tick)
                baud_cnt <= 9'b0;
            else
                baud_cnt <= baud_cnt + 1;
        end

        //bit counter
        if(state != SEND)
            bit_cnt <= 0;
        else if (baud_tick) begin

            if (bit_cnt < 7) begin
                bit_cnt <= bit_cnt + 1;
            end

            else begin
                bit_cnt <= 0;
            end
        end 
    end
end

//TX output combinational circuit use =
always @(*) begin

    case (state)

            IDLE: 
                tx = 1'b1;

            START: 
                tx = 1'b0;

            SEND: 
                tx = tx_shift_reg[bit_cnt];     

            STOP:
                tx = 1'b1; 
            
            default:
                tx = 1'b1;   
    endcase
end


endmodule