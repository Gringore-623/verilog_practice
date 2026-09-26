module fifo_sync (
    parameter DATA_WIDTH = 8;
    parameter DEPTH = 16;
)(
    input clk,
    input rst,
    input [DATA_WIDTH - 1:0] wr_data,
    input wr_en,
    input rd_en,
    output reg  [DATA_WIDTH - 1:0] rd_data,
    output full,
    output empty;
);


localparam ADDR_WIDTH = $clog2(DEPTH);

reg [DATA_WIDTH - 1:0] mem [0:DEPTH-1];

reg [ADDR_WIDTH - 1:0] wr_ptr, rd_ptr;
 
reg [ADDR_WIDTH : 0] count;

assign full = (count == DEPTH) ;
assign empty = (count == 0) ;

wire wr_fire, rd_fire;

assign wr_fire = wr_en && !full ;
assign rd_fire = rd_en && (!empty || wr_fire);

//assign empty = (rd_ptr == 0)

//adress control
always @(posedge clk) begin
    if (rst) begin

        wr_ptr <= 0;
        rd_ptr <= 0;
        count  <= 0;

    end 
    else begin

        if (wr_ptr == DEPTH - 1) begin

            wr_ptr <= 0; 

        else if (wr_fire) begin

            wr_ptr <= wr_ptr + 1'b1;

        end 
        end

        if (rd_ptr == DEPTH - 1) begin

            rd_ptr <= 0; 

        else if (rd_fire) begin

            rd_ptr <= rd_ptr + 1'b1;

        end 
        end
        

        case ({wr_fire, rd_fire})

            2'b10:begin
                count <= count + 1;
            end

            2'b01:begin
                count <= count - 1;
            end

            default: 
                count <= count;
        endcase
    end
end

//data control
always @(posedge clk) begin
    //在清空pointer的情况下没必要清空存储数据
    //if (rst) begin
        //[DATA_WIDTH - 1:0] mem [0:DEPTH-1] <= 0;
    //end 
        
        if (wr_fire) begin
            mem[wr_ptr] <= wr_data;
        end

        if (rd_fire) begin
            rd_data <= mem[rd_ptr];
        end
end

endmodule