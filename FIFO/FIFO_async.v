module fifo_async #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16
)(
    input wr_clk,
    input rd_clk,

    input wr_rst,
    input rd_rst,

    input wr_en,
    input [DATA_WIDTH - 1:0] wr_data,
    
    input rd_en,
    output reg  [DATA_WIDTH - 1:0] rd_data,

    output reg full,
    output reg empty
);


localparam ADDR_WIDTH = $clog2(DEPTH);

reg [DATA_WIDTH - 1:0] mem [0:DEPTH-1];

// ============================================================
// fire logic
// ============================================================

wire wr_fire, rd_fire;

assign wr_fire = wr_en && !full;
assign rd_fire = rd_en && !empty;

// ============================================================
// write pointer
// ============================================================

reg [ADDR_WIDTH:0] binary_wr_ptr;
reg [ADDR_WIDTH:0] grey_wr_ptr;

wire [ADDR_WIDTH:0] binary_wr_ptr_next;
wire [ADDR_WIDTH:0] grey_wr_ptr_next;

// ============================================================
// Read pointer
// ============================================================

reg [ADDR_WIDTH:0] binary_rd_ptr;
reg [ADDR_WIDTH:0] grey_rd_ptr;

wire [ADDR_WIDTH:0] binary_rd_ptr_next;
wire [ADDR_WIDTH:0] grey_rd_ptr_next;

// ============================================================
// CDC synchronizer
// ============================================================

reg [ADDR_WIDTH:0] meta_grey_wr_ptr, sync_grey_wr_ptr;
reg [ADDR_WIDTH:0] meta_grey_rd_ptr, sync_grey_rd_ptr;

// ============================================================
// Next pointer logic
// ============================================================

assign binary_wr_ptr_next = binary_wr_ptr + wr_fire;

assign grey_wr_ptr_next =
    (binary_wr_ptr_next >> 1) ^ binary_wr_ptr_next;

assign binary_rd_ptr_next = binary_rd_ptr + rd_fire;

assign grey_rd_ptr_next =
    (binary_rd_ptr_next >> 1) ^ binary_rd_ptr_next;

// ============================================================
// Next full/empty logic
// ============================================================

wire full_next, empty_next;
//full determine logic
assign full_next =
    (grey_wr_ptr_next ==
     {~sync_grey_rd_ptr[ADDR_WIDTH:ADDR_WIDTH-1],
       sync_grey_rd_ptr[ADDR_WIDTH-2:0]});

//empty determine logic
assign empty_next =
    (grey_rd_ptr_next == sync_grey_wr_ptr);


// ============================================================
// CDC: wr_gray -> read domain
// ============================================================

always @(posedge rd_clk) begin
    if (rd_rst) begin

        meta_grey_wr_ptr <= 0;
        sync_grey_wr_ptr <= 0;

    end 
    else begin
        
        meta_grey_wr_ptr <= grey_wr_ptr;
        sync_grey_wr_ptr <= meta_grey_wr_ptr;

    end
end

// ============================================================
// CDC: rd_gray -> write domain
// ============================================================

always @(posedge wr_clk) begin
    if (wr_rst) begin

        meta_grey_rd_ptr <= 0;
        sync_grey_rd_ptr <= 0;

    end 
    else begin
        
        meta_grey_rd_ptr <= grey_rd_ptr;
        sync_grey_rd_ptr <= meta_grey_rd_ptr;

    end
end

// ============================================================
// write domain control
// ============================================================
always @(posedge wr_clk) begin
    if (wr_rst) begin

        binary_wr_ptr   <= 0;
        grey_wr_ptr     <= 0;
        full            <= 0;

    end
    else begin
        //address control
        binary_wr_ptr   <= binary_wr_ptr_next; 
        grey_wr_ptr     <= grey_wr_ptr_next;
        full            <= full_next;

        if (wr_fire) begin
        //data control
        mem[binary_wr_ptr[ADDR_WIDTH-1:0]] <= wr_data;
        end
    end
end

// ============================================================
// read domain control
// ============================================================
always @(posedge rd_clk) begin
    if (rd_rst) begin

        binary_rd_ptr   <= 0;
        grey_rd_ptr     <= 0;
        empty           <= 1;
        rd_data         <= 0;

    end
    else begin
        //address control
        binary_rd_ptr   <= binary_rd_ptr_next; 
        grey_rd_ptr     <= grey_rd_ptr_next;
        empty            <= empty_next;

        if (rd_fire) begin
        //data control
        rd_data <= mem[binary_rd_ptr[ADDR_WIDTH-1:0]];
        end
    end
end

endmodule