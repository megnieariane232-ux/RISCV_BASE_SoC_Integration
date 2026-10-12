module aximem_ss (


    input clk, resetn,

    // AXI slave memory subsystem

    input         mem_axi_awvalid,
    output        mem_axi_awready,
    input  [31:0] mem_axi_awaddr,
   

    input         mem_axi_wvalid,
    output        mem_axi_wready,
    input  [31:0] mem_axi_wdata,
    input  [ 3:0] mem_axi_wstrb,

    output        mem_axi_bvalid,
    input         mem_axi_bready,

    input         mem_axi_arvalid,
    output        mem_axi_arready,
    input  [31:0] mem_axi_araddr,
   

    output        mem_axi_rvalid,
    input         mem_axi_rready,
    output [31:0] mem_axi_rdata


);

    wire        mem_valid;
    wire        mem_ready;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0]  mem_wstrb;
    wire [31:0] mem_rdata;

    axi_slave_adapter u_axi_slave_adapter(

        .clk            (clk),
        .resetn         (resetn),	
        .axi_arvalid    (mem_axi_arvalid),
        .axi_arready    (mem_axi_arready),
        .axi_araddr     (mem_axi_araddr),
        .axi_rvalid     (mem_axi_rvalid),
        .axi_rready     (mem_axi_rready),
        .axi_rdata      (mem_axi_rdata),
        .axi_awvalid    (mem_axi_awvalid),
        .axi_awready    (mem_axi_awready),
        .axi_awaddr     (mem_axi_awaddr),
        .axi_wvalid     (mem_axi_wvalid),
        .axi_wready     (mem_axi_wready),
        .axi_wdata      (mem_axi_wdata),
        .axi_wstrb      (mem_axi_wstrb),
        .axi_bvalid     (mem_axi_bvalid),
        .axi_bready     (mem_axi_bready),
        .valid          (mem_valid),
        .ready          (mem_ready),
        .addr           (mem_addr),
        .wdata          (mem_wdata),
        .wstrb          (mem_wstrb),
        .rdata          (mem_rdata)

    );

    sram u_sram(

        .clk       (clk),
        .reset_n   (resetn),
        .valid     (mem_valid),
        .ready     (mem_ready),
        .addr      (mem_addr),
        .wdata     (mem_wdata),
        .wstrb     (mem_wstrb),
        .rdata     (mem_rdata)

    );




endmodule
