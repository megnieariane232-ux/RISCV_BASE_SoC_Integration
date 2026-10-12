
//*** 64KiB memory ***//
module sram #(
    parameter WIDTH = 32,
    parameter DEPTH = 16384
)(
    input                      clk,
    input                      reset_n,
    input                      valid,
    output                     ready,

    input  [31:0]              addr,
    input  [WIDTH-1:0]         wdata,
    input  [(WIDTH/8)-1:0]     wstrb,
    output [WIDTH-1:0]         rdata
);

    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg [WIDTH-1:0] mem [0:DEPTH-1];

    wire [ADDR_WIDTH-1:0] word_addr;

    assign word_addr = addr[ADDR_WIDTH+1:2];

    assign ready = 1'b1;

    assign rdata = mem[word_addr];

    always @(posedge clk) begin
        if (valid && wstrb!=0) begin
            if (wstrb[0])
                mem[word_addr][7:0] <= wdata[7:0];

            if (wstrb[1])
                mem[word_addr][15:8] <= wdata[15:8];

            if (wstrb[2])
                mem[word_addr][23:16] <= wdata[23:16];

            if (wstrb[3])
                mem[word_addr][31:24] <= wdata[31:24];
        end
    end

endmodule
