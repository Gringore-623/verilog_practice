module apb_top (
    input  wire        PCLK,
    input  wire        PRESETn,

    // APB input from master
    input  wire [31:0] PADDR,
    input  wire        PWRITE,
    input  wire [31:0] PWDATA,
    input  wire        PSEL,
    input  wire        PENABLE,

    // APB output to master
    output reg        PREADY,
    output reg  [31:0] PRDATA,
    output reg        PSLVERR
);

wire [3:0] slave_psel;
wire [3:0] slave_pready;
wire [31:0] slave_prdata [0:3];
wire [3:0] slave_pslverr;

//address decode
assign slave_psel[0] = PSEL && (PADDR[13:12] == 2'b00);
assign slave_psel[1] = PSEL && (PADDR[13:12] == 2'b01);
assign slave_psel[2] = PSEL && (PADDR[13:12] == 2'b10);
assign slave_psel[3] = PSEL && (PADDR[13:12] == 2'b11);

//generate 4 slave
genvar i;
generate
    for (i = 0; i<4; i++) begin : GEN_APB_SLAVE

        apb_slave u_apb_slave (
            .PCLK(PCLK),
            .PRESETn(PRESETn),

            .PADDR    (PADDR),
            .PWRITE   (PWRITE),
            .PWDATA   (PWDATA),
            .PSEL     (slave_psel[i]),
            .PENABLE  (PENABLE),

            .PREADY   (slave_pready[i]),
            .PRDATA   (slave_prdata[i]),
            .PSLVERR  (slave_pslverr[i])
        );

    end
endgenerate

//response MUX

always @(*) begin

        PREADY  = 1'b0;
        PRDATA  = 32'b0;
        PSLVERR = 1'b0;

        case (slave_psel)
            4'b0001: begin
                PREADY = slave_pready[0];
                PRDATA = slave_prdata[0];
                PSLVERR = slave_pslverr[0];
            end   

            4'b0010:  begin
                PREADY = slave_pready[1];
                PRDATA = slave_prdata[1];
                PSLVERR = slave_pslverr[1];
            end  

            4'b0100:  begin
                PREADY = slave_pready[2];
                PRDATA = slave_prdata[2];
                PSLVERR = slave_pslverr[2];
            end  

            4'b1000:  begin
                PREADY = slave_pready[3];
                PRDATA = slave_prdata[3];
                PSLVERR = slave_pslverr[3];
            end  

            default: begin
                PREADY  = 1'b0;
                PRDATA  = 32'b0;
                PSLVERR = 1'b0;
            end

        endcase
end

endmodule

module apb_slave (
    input  wire        PCLK,
    input  wire        PRESETn,

    // APB input from master
    input  wire [31:0] PADDR,
    input  wire        PWRITE,
    input  wire [31:0] PWDATA,
    input  wire        PSEL,
    input  wire        PENABLE,

    // APB output to master
    output wire        PREADY,
    output reg  [31:0] PRDATA,
    output wire        PSLVERR
);

reg [31:0] data_reg [0:3];
wire [3:0] register_sel;

//MUX select register inside slave
assign register_sel[0] = PSEL && (PADDR[3:2] == 2'b00);
assign register_sel[1] = PSEL && (PADDR[3:2] == 2'b01);
assign register_sel[2] = PSEL && (PADDR[3:2] == 2'b10);
assign register_sel[3] = PSEL && (PADDR[3:2] == 2'b11);


assign PREADY = 1'b1;
assign PSLVERR = 1'b0;

wire apb_write, apb_read;
//write logic
assign  apb_write =
    PSEL && PENABLE && PWRITE;
//read logic
assign  apb_read =
    PSEL && PENABLE && !PWRITE;


always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin

            data_reg[0] <= 32'b0;
            data_reg[1] <= 32'b0;
            data_reg[2] <= 32'b0;
            data_reg[3] <= 32'b0;

        end
        else if (apb_write) begin//write

            case (register_sel)
            4'b0001: begin
                data_reg[0] <= PWDATA;
            end
            4'b0010: begin
                data_reg[1] <= PWDATA;
            end
            4'b0100: begin
                data_reg[2] <= PWDATA;
            end
            4'b1000: begin
                data_reg[3] <= PWDATA;
            end
        endcase

        end
end


always @(*) begin

    PRDATA = 32'b0;//default read value

    if (apb_read) begin//read

        case (register_sel)

            4'b0001: begin
                PRDATA = data_reg[0];
            end
            4'b0010: begin
                PRDATA = data_reg[1];
            end
            4'b0100: begin
                PRDATA = data_reg[2];
            end
            4'b1000: begin
                PRDATA = data_reg[3];
            end
            default:begin
                PRDATA = 32'b0;
            end

        endcase
    end
end

endmodule