module apb_master (
    input  wire        PCLK,
    input  wire        PRESETn,

    // upstream request
    input  wire        req,
    input  wire [31:0] req_addr,
    input  wire        req_write,
    input  wire [31:0] req_wdata,

    // APB slave response
    input  wire        PREADY,
    input  wire [31:0] PRDATA,

    // APB outputs
    output wire [31:0] PADDR,
    output wire        PWRITE,
    output wire [31:0] PWDATA,
    output wire        PSEL,
    output wire        PENABLE,

    // upstream response
    output wire        done,
    output reg  [31:0] rdata   
);

    //  定义 IDLE / SETUP / ACCESS 三个状态
    parameter   IDLE    = 2'b00,
                SETUP   = 2'b01,
                ACCESS  = 2'b10;

// ============================================================
// state transfer logic
// ============================================================
    // state register 
    reg [1:0] state, next_state;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            state <= IDLE;
        else
            state <= next_state;
    end

    // next-state combinational logic
    always @(*) begin
        next_state = state;

        case (state)

            IDLE:begin
                if (req) begin
                    next_state = SETUP;
                end
            end

            SETUP:begin
                next_state = ACCESS;
            end 

            ACCESS:begin
                if (PREADY) begin
                    next_state = IDLE;
                end
            end

            default:next_state = IDLE; 
        endcase
    end

// ============================================================
// upstream request
// ============================================================

    // data register
    reg [31:0] addr_reg;
    reg        write_reg;
    reg [31:0] wdata_reg;

    // latch data register
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin

            addr_reg    <= 32'b0;
            wdata_reg   <= 32'b0;
            write_reg   <= 0;

        end
        else if (state == IDLE && req) begin

            addr_reg    <= req_addr;
            wdata_reg   <= req_wdata;
            write_reg   <= req_write;

        end
    end

    
// ============================================================
// APB output
// ============================================================
    //output from APB register
    assign PADDR  = addr_reg;
    assign PWRITE = write_reg;
    assign PWDATA = wdata_reg;
    
// ============================================================
// APB read response from APB slave
// ============================================================
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin

            rdata    <= 32'b0;

        end
        else if (state == ACCESS && PREADY && !write_reg) begin

            rdata <= PRDATA;
 
        end
    end

    // 生成 PSEL / PENABLE
    assign PSEL = (state == SETUP) || (state == ACCESS);
    assign PENABLE = (state == ACCESS);

    // done 应该在哪个条件下拉高？
    assign done = (state == ACCESS) && (PREADY);
        


   



    

endmodule