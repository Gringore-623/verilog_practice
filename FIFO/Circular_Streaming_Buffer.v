module fifo_circular (
    input clk,
    input rst,
    input [7:0] wr_data,
    input wr_en,
    input rd_en,
    output [7:0] rd_data,
    output 
);

parameter DATA_WIDTH = 8;
parameter DEPTH = 16;
localparam ADDR_WIDTH = $clog2(DEPTH);

reg [DATA_WIDTH - 1:0] mem [0:DEPTH-1];
reg [ADDR_WIDTH - 1:0] addr;
reg [ADDR_WIDTH - 1:0] wr_ptr, rd_ptr;

assign empty = ~ full;
reg    full; 

//assign empty = (rd_ptr == 0)

//adress control
always @(posedge clk) begin
    if (rst) begin

        wr_ptr <= 0;
        rd_ptr <= 1;
        full  <= 0;

    end else begin
        if (rd_ptr == ADDR_WIDTH - 1) begin

            rd_ptr <= 0;
            full <= 1;
            
        end

        else if (wr_ptr == ADDR_WIDTH - 1) begin

            wr_ptr <= 0;
            
        end

        else (wr_en) begin
            wr_ptr <= wr_ptr + 1'b1;
            rd_ptr <= rd_ptr + 1'b1;
        end
    end
end

//data control
always @(posedge clk) begin
    if (rst) begin
        [DATA_WIDTH - 1:0] mem [0:DEPTH-1] <= 0;
    end

    else if (wr_en) begin
        mem[wr_ptr] <= wr_data;
    end

    else if (rd_en && !empty) begin
        rd_data <= mem[rd_ptr]
    end
end

endmodule