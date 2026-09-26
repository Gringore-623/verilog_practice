`timescale 1ns/1ps

module fifo_sync_tb;

    // -------------------------------------------------
    // Parameters
    // -------------------------------------------------
    parameter DATA_WIDTH = 8;
    parameter DEPTH      = 16;

    // -------------------------------------------------
    // DUT signals
    // -------------------------------------------------
    reg                     clk;
    reg                     rst;

    reg  [DATA_WIDTH-1:0]    wr_data;
    reg                     wr_en;
    reg                     rd_en;

    wire [DATA_WIDTH-1:0]    rd_data;
    wire                    full;
    wire                    empty;


    // -------------------------------------------------
    // DUT instance
    // -------------------------------------------------
    fifo_sync #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk     (clk),
        .rst     (rst),
        .wr_data (wr_data),
        .wr_en   (wr_en),
        .rd_en   (rd_en),
        .rd_data (rd_data),
        .full    (full),
        .empty   (empty)
    );


    // -------------------------------------------------
    // Clock generation
    // 10 ns period -> 100 MHz
    // -------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end


    // -------------------------------------------------
    // Write task
    // -------------------------------------------------
    task fifo_write;
        input [DATA_WIDTH-1:0] data;
        begin
            @(negedge clk);

            wr_en   = 1'b1;
            wr_data = data;

            @(negedge clk);

            wr_en   = 1'b0;
            wr_data = 0;
        end
    endtask


    // -------------------------------------------------
    // Read task
    // -------------------------------------------------
    task fifo_read;
        begin
            @(negedge clk);

            rd_en = 1'b1;

            @(negedge clk);

            rd_en = 1'b0;
        end
    endtask


    // -------------------------------------------------
    // Simultaneous read + write
    // -------------------------------------------------
    task fifo_read_write;
        input [DATA_WIDTH-1:0] data;
        begin
            @(negedge clk);

            wr_en   = 1'b1;
            rd_en   = 1'b1;
            wr_data = data;

            @(negedge clk);

            wr_en   = 1'b0;
            rd_en   = 1'b0;
            wr_data = 0;
        end
    endtask


    // -------------------------------------------------
    // Test sequence
    // -------------------------------------------------
    integer i;

    initial begin

        // default values
        rst     = 1'b1;
        wr_en   = 1'b0;
        rd_en   = 1'b0;
        wr_data = 0;


        // -------------------------------------------------
        // TEST 0: Reset
        // -------------------------------------------------
        repeat (3) @(posedge clk);

        rst = 1'b0;

        @(posedge clk);

        $display("=================================");
        $display("TEST 0: Reset");
        $display("empty = %b, full = %b", empty, full);
        $display("=================================");


        // -------------------------------------------------
        // TEST 1: Write one data
        // -------------------------------------------------
        $display("TEST 1: Write one data");

        fifo_write(8'hA1);

        $display(
            "After write: empty=%b full=%b",
            empty,
            full
        );


        // -------------------------------------------------
        // TEST 2: Read one data
        // -------------------------------------------------
        $display("TEST 2: Read one data");

        fifo_read();

        $display(
            "Read data = %h",
            rd_data
        );


        // -------------------------------------------------
        // TEST 3: Fill FIFO
        // -------------------------------------------------
        $display("TEST 3: Fill FIFO");

        for (i = 0; i < DEPTH; i = i + 1) begin
            fifo_write(i);
        end

        $display(
            "After filling: empty=%b full=%b",
            empty,
            full
        );


        // -------------------------------------------------
        // TEST 4: Write while full
        // -------------------------------------------------
        $display("TEST 4: Write while full");

        fifo_write(8'hFF);

        $display(
            "After write attempt: full=%b",
            full
        );


        // -------------------------------------------------
        // TEST 5: Read FIFO completely
        // -------------------------------------------------
        $display("TEST 5: Read FIFO");

        for (i = 0; i < DEPTH; i = i + 1) begin
            fifo_read();

            $display(
                "Read [%0d] = %h",
                i,
                rd_data
            );
        end


        // -------------------------------------------------
        // TEST 6: Read while empty
        // -------------------------------------------------
        $display("TEST 6: Read while empty");

        fifo_read();

        $display(
            "After read attempt: empty=%b",
            empty
        );


        // -------------------------------------------------
        // TEST 7: Simultaneous read/write
        // -------------------------------------------------
        $display("TEST 7: Simultaneous R/W");

        fifo_write(8'h11);
        fifo_write(8'h22);
        fifo_write(8'h33);

        fifo_read_write(8'h44);

        $display(
            "rd_data=%h empty=%b full=%b",
            rd_data,
            empty,
            full
        );


        // -------------------------------------------------
        // TEST 8: Full + simultaneous R/W
        // -------------------------------------------------

        // TODO:
        // 1. fill FIFO
        // 2. assert rd_en + wr_en at same cycle
        // 3. verify:
        //      read succeeds
        //      write succeeds
        //      full remains asserted


        // -------------------------------------------------
        // End simulation
        // -------------------------------------------------

        #20;

        $display("=================================");
        $display("Simulation finished");
        $display("=================================");

        $finish;

    end


    // -------------------------------------------------
    // Optional waveform dump
    // -------------------------------------------------
    initial begin
        $dumpfile("fifo_sync_tb.vcd");
        $dumpvars(0, fifo_sync_tb);
    end

endmodule