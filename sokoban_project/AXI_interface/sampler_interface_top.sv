`timescale 1 ns / 1 ps

module sampler_interface_top #
(
    parameter integer DATA_WIDTH	= 32,
    parameter integer ADDR_WIDTH	= 14
)
(
    output logic hdmi_tmds_clk_n,
    output logic hdmi_tmds_clk_p,
    output logic [2:0] hdmi_tmds_data_n,
    output logic [2:0] hdmi_tmds_data_p,
    
    // Ports of Axi Slave Bus Interface AXI
    input logic  axi_aclk,
    input logic  axi_aresetn,
    input logic [ADDR_WIDTH-1 : 0] axi_awaddr,
    input logic [2 : 0] axi_awprot,
    input logic  axi_awvalid,
    output logic  axi_awready,
    input logic [DATA_WIDTH-1 : 0] axi_wdata,
    input logic [(DATA_WIDTH/8)-1 : 0] axi_wstrb,
    input logic  axi_wvalid,
    output logic  axi_wready,
    output logic [1 : 0] axi_bresp,
    output logic  axi_bvalid,
    input logic  axi_bready,
    input logic [ADDR_WIDTH-1 : 0] axi_araddr,
    input logic [2 : 0] axi_arprot,
    input logic  axi_arvalid,
    output logic  axi_arready,
    output logic [DATA_WIDTH-1 : 0] axi_rdata,
    output logic [1 : 0] axi_rresp,
    output logic  axi_rvalid,
    input logic  axi_rready
);

/////////////////////////////////////////////////////////////////////////////
// 100MHz AXI clock -> 25MHz pixel clock & 125MHz HDMI serialization clock

    logic clk_125MHz, clk_25MHz;
    logic locked;
    
    clk_wiz_0 clk_wiz (
        .clk_out1(clk_125MHz),
        .clk_out2(clk_25MHz),
        .resetn(axi_aresetn),
        .locked(locked),
        .clk_in1(axi_aclk)
    );
    
/////////////////////////////////////////////////////////////////////////////
// reset synchronization

    logic rst_raw;
    assign rst_raw = ~axi_aresetn | ~locked;
    
    logic [1:0] rst_sync_25MHz;
    always_ff @(posedge clk_25MHz or posedge rst_raw) begin
        if (rst_raw) rst_sync_25MHz <= 2'b11;
        else rst_sync_25MHz <= {rst_sync_25MHz[0], 1'b0};
    end
    logic reset_25MHz;
    assign reset_25MHz = rst_sync_25MHz[1];
    
//////////////////////////////////////////////////////////////////////////////

    logic [8:0] axi_map_addr;
    logic [7:0] axi_map_wdata, axi_map_rdata;
    logic axi_map_ena, axi_map_we;

    logic [11:0] axi_tile_addr;
    logic [7:0] axi_tile_wdata, axi_tile_rdata;
    logic axi_tile_ena, axi_tile_we;

    logic [(DATA_WIDTH/4)-1:0] palette;
    logic [(DATA_WIDTH/4)-1:0] frame_count;
    
    render_pipeline renderer (
        .clk_axi(axi_aclk),
        .clk_25MHz(clk_25MHz),
        .clk_125MHz(clk_125MHz),
        .reset_axi(rst_raw),
        .reset_25MHz(reset_25MHz),

        .axi_map_addr(axi_map_addr),
        .axi_map_wdata(axi_map_wdata),
        .axi_map_ena(axi_map_ena),
        .axi_map_we(axi_map_we),
        .axi_map_rdata(axi_map_rdata),
        
        .axi_tile_addr(axi_tile_addr),
        .axi_tile_wdata(axi_tile_wdata),
        .axi_tile_ena(axi_tile_ena),
        .axi_tile_we(axi_tile_we),
        .axi_tile_rdata(axi_tile_rdata),

        .palette(palette),
        .frame_count(frame_count),

        .hdmi_tmds_clk_n(hdmi_tmds_clk_n),
        .hdmi_tmds_clk_p(hdmi_tmds_clk_p),
        .hdmi_tmds_data_n(hdmi_tmds_data_n),
        .hdmi_tmds_data_p(hdmi_tmds_data_p)
    );
    
//////////////////////////////////////////////////////////////////////////////////////////
// AXI interface 8-bit reads and writes

    sampler_axi_interface # (
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) axi_interface (
    
        // logic interface signals
        .map_addr(axi_map_addr),
        .map_wdata(axi_map_wdata),
        .map_ena(axi_map_ena),
        .map_we(axi_map_we),
        .map_rdata(axi_map_rdata),
        .tile_addr(axi_tile_addr),
        .tile_wdata(axi_tile_wdata),
        .tile_ena(axi_tile_ena),
        .tile_we(axi_tile_we),
        .tile_rdata(axi_tile_rdata),
        .palette_reg(palette),
        .frame_count(frame_count),
        
        .S_AXI_ACLK(axi_aclk),
        .S_AXI_ARESETN(axi_aresetn),
        .S_AXI_AWADDR(axi_awaddr),
        .S_AXI_AWPROT(axi_awprot),
        .S_AXI_AWVALID(axi_awvalid),
        .S_AXI_AWREADY(axi_awready),
        .S_AXI_WDATA(axi_wdata),
        .S_AXI_WSTRB(axi_wstrb),
        .S_AXI_WVALID(axi_wvalid),
        .S_AXI_WREADY(axi_wready),
        .S_AXI_BRESP(axi_bresp),
        .S_AXI_BVALID(axi_bvalid),
        .S_AXI_BREADY(axi_bready),
        .S_AXI_ARADDR(axi_araddr),
        .S_AXI_ARPROT(axi_arprot),
        .S_AXI_ARVALID(axi_arvalid),
        .S_AXI_ARREADY(axi_arready),
        .S_AXI_RDATA(axi_rdata),
        .S_AXI_RRESP(axi_rresp),
        .S_AXI_RVALID(axi_rvalid),
        .S_AXI_RREADY(axi_rready)
    );

endmodule