`timescale 1ns/1ps

module aximem_ss_tb;

    localparam CLK_PERIOD = 10;
    localparam TIMEOUT_CYCLES = 40;

    logic        clk;
    logic        resetn;

    logic        mem_axi_awvalid;
    wire         mem_axi_awready;
    logic [31:0] mem_axi_awaddr;

    logic        mem_axi_wvalid;
    wire         mem_axi_wready;
    logic [31:0] mem_axi_wdata;
    logic [ 3:0] mem_axi_wstrb;

    wire         mem_axi_bvalid;
    logic        mem_axi_bready;

    logic        mem_axi_arvalid;
    wire         mem_axi_arready;
    logic [31:0] mem_axi_araddr;

    wire         mem_axi_rvalid;
    logic        mem_axi_rready;
    wire  [31:0] mem_axi_rdata;

    int errors;

    aximem_ss dut (
        .clk             (clk),
        .resetn          (resetn),
        .mem_axi_awvalid (mem_axi_awvalid),
        .mem_axi_awready (mem_axi_awready),
        .mem_axi_awaddr  (mem_axi_awaddr),
        .mem_axi_wvalid  (mem_axi_wvalid),
        .mem_axi_wready  (mem_axi_wready),
        .mem_axi_wdata   (mem_axi_wdata),
        .mem_axi_wstrb   (mem_axi_wstrb),
        .mem_axi_bvalid  (mem_axi_bvalid),
        .mem_axi_bready  (mem_axi_bready),
        .mem_axi_arvalid (mem_axi_arvalid),
        .mem_axi_arready (mem_axi_arready),
        .mem_axi_araddr  (mem_axi_araddr),
        .mem_axi_rvalid  (mem_axi_rvalid),
        .mem_axi_rready  (mem_axi_rready),
        .mem_axi_rdata   (mem_axi_rdata)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin
        $timeformat(-9, 2, "ns", 0);
        $dumpfile("aximem_ss_tb.vcd");
        $dumpvars(0, aximem_ss_tb);
    end

    initial begin
        logic [31:0] rdata;

        clk = 1'b0;
        resetn = 1'b0;
        errors = 0;
        drive_idle();

        repeat (5) @(posedge clk);
        @(negedge clk);
        resetn = 1'b1;
        repeat (2) @(negedge clk);

        check_idle_after_reset();

        axi_write(32'h0000_0010, 32'hDEAD_BEEF, 4'hF);
        axi_read(32'h0000_0010, rdata);
        expect_word(rdata, 32'hDEAD_BEEF, "full word write/read");

        axi_write(32'h0000_0020, 32'h1122_3344, 4'hF);
        axi_write(32'h0000_0020, 32'hAA55_DD77, 4'b0101);
        axi_read(32'h0000_0020, rdata);
        expect_word(rdata, 32'h1155_3377, "byte strobes update bytes 0 and 2");

        axi_write_w_first(32'h0000_0024, 32'hCAFE_BABE, 4'hF, 3);
        axi_read(32'h0000_0024, rdata);
        expect_word(rdata, 32'hCAFE_BABE, "write data before write address");

        axi_write_b_stall(32'h0000_0028, 32'h0BAD_C0DE, 4'hF, 3);
        axi_read_r_stall(32'h0000_0028, rdata, 3);
        expect_word(rdata, 32'h0BAD_C0DE, "read data held while rready is low");

        axi_write_read_collision();

        if (errors == 0) begin
            $display("[%0t] [PASS] aximem_ss_tb completed successfully", $realtime);
            $finish;
        end

        $fatal(1, "[%0t] [FAIL] aximem_ss_tb completed with %0d error(s)",
               $realtime, errors);
    end

    task automatic drive_idle;
        begin
            mem_axi_awvalid = 1'b0;
            mem_axi_awaddr  = 32'b0;
            mem_axi_wvalid  = 1'b0;
            mem_axi_wdata   = 32'b0;
            mem_axi_wstrb   = 4'b0;
            mem_axi_bready  = 1'b0;
            mem_axi_arvalid = 1'b0;
            mem_axi_araddr  = 32'b0;
            mem_axi_rready  = 1'b0;
        end
    endtask

    task automatic check_idle_after_reset;
        begin
            expect_bit(mem_axi_awready, 1'b1, "awready after reset");
            expect_bit(mem_axi_wready,  1'b1, "wready after reset");
            expect_bit(mem_axi_arready, 1'b1, "arready after reset");
            expect_bit(mem_axi_bvalid,  1'b0, "bvalid after reset");
            expect_bit(mem_axi_rvalid,  1'b0, "rvalid after reset");
        end
    endtask

    task automatic axi_write(
        input logic [31:0] addr,
        input logic [31:0] data,
        input logic [ 3:0] strb
    );
        bit aw_done;
        bit w_done;
        int cycles;
        begin
            aw_done = 1'b0;
            w_done = 1'b0;
            cycles = 0;

            @(negedge clk);
            mem_axi_awaddr  = addr;
            mem_axi_awvalid = 1'b1;
            mem_axi_wdata   = data;
            mem_axi_wstrb   = strb;
            mem_axi_wvalid  = 1'b1;
            mem_axi_bready  = 1'b1;

            while (!aw_done || !w_done) begin
                @(posedge clk);
                if (mem_axi_awvalid && mem_axi_awready) aw_done = 1'b1;
                if (mem_axi_wvalid && mem_axi_wready)   w_done  = 1'b1;

                @(negedge clk);
                if (aw_done) mem_axi_awvalid = 1'b0;
                if (w_done)  mem_axi_wvalid  = 1'b0;

                cycles++;
                if (cycles > TIMEOUT_CYCLES)
                    $fatal(1, "[%0t] [TIMEOUT] write address/data handshake",
                           $realtime);
            end

            wait_for_bvalid("write response");
            @(posedge clk);
            @(negedge clk);
            mem_axi_bready = 1'b0;
            mem_axi_awaddr = 32'b0;
            mem_axi_wdata  = 32'b0;
            mem_axi_wstrb  = 4'b0;
        end
    endtask

    task automatic axi_write_w_first(
        input logic [31:0] addr,
        input logic [31:0] data,
        input logic [ 3:0] strb,
        input int          gap_cycles
    );
        int cycles;
        begin
            cycles = 0;

            @(negedge clk);
            mem_axi_wdata  = data;
            mem_axi_wstrb  = strb;
            mem_axi_wvalid = 1'b1;
            mem_axi_bready = 1'b1;

            while (!mem_axi_wready) begin
                @(negedge clk);
                cycles++;
                if (cycles > TIMEOUT_CYCLES)
                    $fatal(1, "[%0t] [TIMEOUT] W handshake in W-before-AW write",
                           $realtime);
            end
            @(posedge clk);
            @(negedge clk);
            mem_axi_wvalid = 1'b0;
            mem_axi_wdata  = 32'b0;
            mem_axi_wstrb  = 4'b0;

            repeat (gap_cycles) @(negedge clk);

            cycles = 0;
            mem_axi_awaddr  = addr;
            mem_axi_awvalid = 1'b1;

            while (!mem_axi_awready) begin
                @(negedge clk);
                cycles++;
                if (cycles > TIMEOUT_CYCLES)
                    $fatal(1, "[%0t] [TIMEOUT] AW handshake in W-before-AW write",
                           $realtime);
            end
            @(posedge clk);
            @(negedge clk);
            mem_axi_awvalid = 1'b0;
            mem_axi_awaddr  = 32'b0;

            wait_for_bvalid("W-before-AW write response");
            @(posedge clk);
            @(negedge clk);
            mem_axi_bready = 1'b0;
        end
    endtask

    task automatic axi_write_b_stall(
        input logic [31:0] addr,
        input logic [31:0] data,
        input logic [ 3:0] strb,
        input int          stall_cycles
    );
        bit aw_done;
        bit w_done;
        int cycles;
        begin
            aw_done = 1'b0;
            w_done = 1'b0;
            cycles = 0;

            @(negedge clk);
            mem_axi_awaddr  = addr;
            mem_axi_awvalid = 1'b1;
            mem_axi_wdata   = data;
            mem_axi_wstrb   = strb;
            mem_axi_wvalid  = 1'b1;
            mem_axi_bready  = 1'b0;

            while (!aw_done || !w_done) begin
                @(posedge clk);
                if (mem_axi_awvalid && mem_axi_awready) aw_done = 1'b1;
                if (mem_axi_wvalid && mem_axi_wready)   w_done  = 1'b1;

                @(negedge clk);
                if (aw_done) mem_axi_awvalid = 1'b0;
                if (w_done)  mem_axi_wvalid  = 1'b0;

                cycles++;
                if (cycles > TIMEOUT_CYCLES)
                    $fatal(1, "[%0t] [TIMEOUT] stalled-B write address/data handshake",
                           $realtime);
            end

            wait_for_bvalid("stalled write response");

            repeat (stall_cycles) begin
                expect_bit(mem_axi_bvalid,  1'b1, "bvalid held while bready is low");
                expect_bit(mem_axi_awready, 1'b0, "awready blocked during pending B");
                expect_bit(mem_axi_wready,  1'b0, "wready blocked during pending B");
                @(negedge clk);
            end

            mem_axi_bready = 1'b1;
            @(posedge clk);
            @(negedge clk);
            mem_axi_bready = 1'b0;
            mem_axi_awaddr = 32'b0;
            mem_axi_wdata  = 32'b0;
            mem_axi_wstrb  = 4'b0;
        end
    endtask

    task automatic axi_read(
        input  logic [31:0] addr,
        output logic [31:0] data
    );
        int cycles;
        begin
            cycles = 0;

            @(negedge clk);
            mem_axi_araddr  = addr;
            mem_axi_arvalid = 1'b1;
            mem_axi_rready  = 1'b1;

            while (!mem_axi_arready) begin
                @(negedge clk);
                cycles++;
                if (cycles > TIMEOUT_CYCLES)
                    $fatal(1, "[%0t] [TIMEOUT] read address handshake",
                           $realtime);
            end
            @(posedge clk);
            @(negedge clk);
            mem_axi_arvalid = 1'b0;
            mem_axi_araddr  = 32'b0;

            wait_for_rvalid("read data");
            data = mem_axi_rdata;

            @(posedge clk);
            @(negedge clk);
            mem_axi_rready = 1'b0;
        end
    endtask

    task automatic axi_read_r_stall(
        input  logic [31:0] addr,
        output logic [31:0] data,
        input  int          stall_cycles
    );
        logic [31:0] held_data;
        int cycles;
        begin
            cycles = 0;

            @(negedge clk);
            mem_axi_araddr  = addr;
            mem_axi_arvalid = 1'b1;
            mem_axi_rready  = 1'b0;

            while (!mem_axi_arready) begin
                @(negedge clk);
                cycles++;
                if (cycles > TIMEOUT_CYCLES)
                    $fatal(1, "[%0t] [TIMEOUT] stalled-R read address handshake",
                           $realtime);
            end
            @(posedge clk);
            @(negedge clk);
            mem_axi_arvalid = 1'b0;
            mem_axi_araddr  = 32'b0;

            wait_for_rvalid("stalled read data");
            held_data = mem_axi_rdata;

            repeat (stall_cycles) begin
                expect_bit(mem_axi_rvalid,  1'b1, "rvalid held while rready is low");
                expect_bit(mem_axi_arready, 1'b0, "arready blocked during pending R");
                expect_word(mem_axi_rdata, held_data, "rdata stable while rready is low");
                @(negedge clk);
            end

            data = mem_axi_rdata;
            mem_axi_rready = 1'b1;
            @(posedge clk);
            @(negedge clk);
            mem_axi_rready = 1'b0;
        end
    endtask

    task automatic axi_write_read_collision;
        logic [31:0] write_addr;
        logic [31:0] read_addr;
        logic [31:0] write_old_data;
        logic [31:0] write_new_data;
        logic [31:0] read_initial_data;
        logic [31:0] read_data;
        bit          read_response_seen;
        int          write_word;
        int          read_word;
        begin
            write_addr        = 32'h0000_0030;
            read_addr         = 32'h0000_0034;
            write_old_data    = 32'h1357_9BDF;
            write_new_data    = 32'h2468_ACE0;
            read_initial_data = 32'hFACE_CAFE;
            read_response_seen = 1'b0;
            write_word        = write_addr[15:2];
            read_word         = read_addr[15:2];

            $display("[%0t] [INFO] starting AW/W versus AR SRAM arbitration test",
                     $realtime);

            axi_write(write_addr, write_old_data, 4'hF);
            axi_write(read_addr, read_initial_data, 4'hF);

            @(negedge clk);
            mem_axi_awaddr  = write_addr;
            mem_axi_awvalid = 1'b1;
            mem_axi_wdata   = write_new_data;
            mem_axi_wstrb   = 4'hF;
            mem_axi_wvalid  = 1'b1;
            mem_axi_bready  = 1'b0;
            mem_axi_rready  = 1'b0;

            @(posedge clk);
            #1;
            expect_bit(dut.u_axi_slave_adapter.aw_pending, 1'b1,
                       "collision: AW transaction is pending after handshake");
            expect_bit(dut.u_axi_slave_adapter.w_pending, 1'b1,
                       "collision: W transaction is pending after handshake");
            expect_bit(dut.u_axi_slave_adapter.ar_pending, 1'b0,
                       "collision: no read transaction is pending yet");
            expect_bit(dut.u_axi_slave_adapter.do_write, 1'b1,
                       "collision: write is ready before AR arrives");

            @(negedge clk);
            mem_axi_awvalid = 1'b0;
            mem_axi_wvalid  = 1'b0;
            mem_axi_awaddr  = 32'b0;
            mem_axi_wdata   = 32'b0;
            mem_axi_wstrb   = 4'b0;
            mem_axi_araddr  = read_addr;
            mem_axi_arvalid = 1'b1;

            @(posedge clk);
            #1;
            mem_axi_arvalid = 1'b0;
            mem_axi_araddr  = 32'b0;

            expect_bit(dut.u_axi_slave_adapter.valid, 1'b1,
                       "collision: pending write is issued to SRAM first");
            expect_word({28'b0, dut.u_axi_slave_adapter.wstrb}, 32'h0000_000F,
                        "collision: issued SRAM transaction is a write");
            expect_word(dut.u_axi_slave_adapter.addr, write_addr,
                        "collision: active SRAM write uses AW address");
            expect_no_active_write_to_addr(read_addr,
                                           "collision: active write must not target AR address");
            expect_bit(dut.u_axi_slave_adapter.ar_pending, 1'b1,
                       "collision: losing AR transaction remains pending while write is active");
            expect_bit(dut.u_axi_slave_adapter.do_read, 1'b0,
                       "collision: read arbitration waits while write is active");
            expect_bit(mem_axi_rvalid, 1'b0,
                       "collision: no read response while SRAM write is active");

            wait_for_bvalid("collision write response");
            expect_bit(mem_axi_bvalid, 1'b1,
                       "collision: write response completes first");
            expect_bit(dut.u_axi_slave_adapter.ar_pending, 1'b1,
                       "collision: read remains pending after write response");

            if (mem_axi_rvalid) begin
                read_response_seen = 1'b1;
                read_data = mem_axi_rdata;
                expect_word(read_data, read_initial_data,
                            "collision: read response data when write completes");
            end

            @(negedge clk);
            mem_axi_bready = 1'b1;
            @(posedge clk);
            #1;
            mem_axi_bready = 1'b0;

            if (!read_response_seen) begin
                wait_for_rvalid("collision read after write completion");
                read_data = mem_axi_rdata;
                expect_word(read_data, read_initial_data,
                            "collision: delayed read returns read-address data");
            end

            @(negedge clk);
            mem_axi_rready = 1'b1;
            @(posedge clk);
            #1;
            mem_axi_rready = 1'b0;

            expect_bit(mem_axi_rvalid, 1'b0,
                       "collision: read response cleared after rready");
            expect_bit(dut.u_axi_slave_adapter.ar_pending, 1'b0,
                       "collision: read transaction is no longer pending");
            expect_bit(mem_axi_arready, 1'b1,
                       "collision: adapter is ready for a new read");
            expect_bit(mem_axi_bvalid, 1'b0,
                       "collision: write response cleared after bready");

            expect_word(dut.u_sram.mem[write_word], write_new_data,
                        "collision: final SRAM data at write address");
            expect_word(dut.u_sram.mem[read_word], read_initial_data,
                        "collision: final SRAM data at read address");

            axi_read(write_addr, read_data);
            expect_word(read_data, write_new_data,
                        "collision: final AXI readback from write address");
            axi_read(read_addr, read_data);
            expect_word(read_data, read_initial_data,
                        "collision: final AXI readback from read address");
        end
    endtask

    task automatic wait_for_bvalid(input string label);
        int cycles;
        begin
            cycles = 0;
            while (!mem_axi_bvalid) begin
                @(negedge clk);
                cycles++;
                if (cycles > TIMEOUT_CYCLES)
                    $fatal(1, "[%0t] [TIMEOUT] %s", $realtime, label);
            end
        end
    endtask

    task automatic wait_for_rvalid(input string label);
        int cycles;
        begin
            cycles = 0;
            while (!mem_axi_rvalid) begin
                @(negedge clk);
                cycles++;
                if (cycles > TIMEOUT_CYCLES)
                    $fatal(1, "[%0t] [TIMEOUT] %s", $realtime, label);
            end
        end
    endtask

    task automatic expect_no_active_write_to_addr(
        input logic [31:0] forbidden_addr,
        input string       label
    );
        begin
            if (dut.u_axi_slave_adapter.valid &&
                (dut.u_axi_slave_adapter.wstrb != 4'b0) &&
                (dut.u_axi_slave_adapter.addr === forbidden_addr)) begin
                errors++;
                $display("[%0t] [FAIL] %s: active write targets forbidden address 0x%08x",
                         $realtime, label, forbidden_addr);
            end else begin
                $display("[%0t] [PASS] %s", $realtime, label);
            end
        end
    endtask

    task automatic expect_word(
        input logic [31:0] got,
        input logic [31:0] expected,
        input string       label
    );
        begin
            if (got !== expected) begin
                errors++;
                $display("[%0t] [FAIL] %s: got 0x%08x, expected 0x%08x",
                         $realtime, label, got, expected);
            end else begin
                $display("[%0t] [PASS] %s: 0x%08x", $realtime, label, got);
            end
        end
    endtask

    task automatic expect_bit(
        input logic got,
        input logic expected,
        input string label
    );
        begin
            if (got !== expected) begin
                errors++;
                $display("[%0t] [FAIL] %s: got %b, expected %b",
                         $realtime, label, got, expected);
            end else begin
                $display("[%0t] [PASS] %s: %b", $realtime, label, got);
            end
        end
    endtask

endmodule
