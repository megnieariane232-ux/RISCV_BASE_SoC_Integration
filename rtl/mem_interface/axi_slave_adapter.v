module axi_slave_adapter #(
    parameter WIDTH = 32
) (

    input  clk,
    input  resetn,

   // READ ADDRESS CHANNEL	
    input          axi_arvalid,
    output reg     axi_arready,
    input   [31:0] axi_araddr,

    // READ DATA CHANNEL
    output reg     axi_rvalid,
    input          axi_rready,
    output reg [WIDTH-1:0] axi_rdata,

    // WRITE ADDRESS CHANNEL
	input          axi_awvalid,
    output reg     axi_awready,
    input   [31:0] axi_awaddr,

    // WRITE DATA CHANNEL
	input           axi_wvalid,
	output reg      axi_wready,
	input [WIDTH-1:0] axi_wdata,
	input [(WIDTH/8)-1:0] axi_wstrb,

	// RESPONSE CHANNEL
	output reg     axi_bvalid,
	input          axi_bready,

	// MEMORY INTERFACE
	output reg                  valid,
	input                       ready,
	output [31:0]               addr,
	output reg [WIDTH-1:0]      wdata,
	output reg [(WIDTH/8)-1:0]  wstrb,
	input   [WIDTH-1:0]         rdata

);

reg [31:0] araddr;
reg [31:0] awaddr;
reg [WIDTH-1:0] wdata_t;
reg [(WIDTH/8)-1:0] wstrb_t;

reg aw_pending;
reg w_pending;
reg ar_pending;

wire do_read;
wire do_write;
wire write_ready;
wire write_active;

assign addr         = do_read ? araddr : awaddr;

assign write_ready  = aw_pending && w_pending;
assign write_active = valid && |wstrb;
assign do_read      = ar_pending && !axi_rvalid && !write_ready && !write_active;
assign do_write     = write_ready && !write_active;

always @(posedge clk or negedge resetn) begin

	if (!resetn) begin 
		axi_arready <= 1'b1;
		axi_awready <= 1'b1;
		axi_rdata   <= {WIDTH{1'b0}};
		axi_rvalid  <= 1'b0;
		araddr      <= 32'b0;
		aw_pending  <= 1'b0;
		w_pending   <= 1'b0;
		ar_pending  <= 1'b0;

		axi_wready  <= 1'b1;
		axi_bvalid  <= 1'b0;
		valid       <= 1'b0;

		awaddr      <= 32'b0;
		wdata       <= {WIDTH{1'b0}};
		wstrb       <= {(WIDTH/8){1'b0}};
		wdata_t     <= {WIDTH{1'b0}};
		wstrb_t     <= {(WIDTH/8){1'b0}};
	end 
	else begin	

	//---------------------------------------------------------//
	//--------------------- AR and R Channels-------------------//
	//---------------------------------------------------------//

            // AR Handshake, capture ARADDRESS, no new address capture 
			if (axi_arvalid && axi_arready) begin 
				araddr       <= axi_araddr;
				ar_pending   <= 1'b1; 
				axi_arready  <= 1'b0;
			end 
			//R Handshake, Read data from SRAM
			if (do_read)begin
				axi_rdata  <= rdata;
				axi_rvalid <= 1'b1;
			end
			// end of read transfer, Ready for new Read request
			if (axi_rready && axi_rvalid) begin
				axi_arready <= 1'b1;
				ar_pending  <= 1'b0;
				axi_rvalid  <= 1'b0;
			end

//--------------------------------------------------------------//
//--------------------- AW, W and B Channels--------------------//
//-------------------------------------------------------------//

			// AW Handshake, AWDDRESS captured, no new address
			if (axi_awvalid && axi_awready) begin
				awaddr      <= axi_awaddr;
				axi_awready <= 1'b0;
				aw_pending  <= 1'b1;
			end
			// W Handshake , awaddress capture
			if (axi_wready && axi_wvalid) begin
			    wdata_t    <= axi_wdata;
				wstrb_t    <= axi_wstrb;
				axi_wready <= 1'b0;
				w_pending  <= 1'b1;
			end
			// Capture data + control data, enable write in SRAM
			if (do_write) begin
				wdata      <= wdata_t;
				wstrb      <= wstrb_t;
				valid      <= 1'b1; //start write transfer
			end
			// wait for Write transfer to end
			if (ready && valid) begin
				valid       <= 1'b0;
                wstrb       <= {(WIDTH/8){1'b0}};
				aw_pending  <= 1'b0;
				w_pending   <= 1'b0;
				axi_bvalid  <= 1'b1;
			end	
			// B Handshake, ready for new write request
			if (axi_bvalid && axi_bready) begin
				axi_awready <= 1'b1;
				axi_wready  <= 1'b1;
				axi_bvalid  <= 1'b0;
			end
	end

end

endmodule
