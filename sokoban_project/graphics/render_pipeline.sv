module render_pipeline (
    input logic clk_axi,
    input logic clk_25MHz,
    input logic clk_125MHz,
    input logic reset_axi,
    input logic reset_25MHz,
    
    input logic [8:0] axi_map_addr,
    input logic [7:0] axi_map_wdata,
    input logic axi_map_ena,
    input logic axi_map_we,
    output logic [7:0] axi_map_rdata,

    input logic [11:0] axi_tile_addr,
    input logic [7:0] axi_tile_wdata,
    input logic axi_tile_ena,
    input logic axi_tile_we,
    output logic [7:0] axi_tile_rdata,
    
    input logic [7:0] palette,
    output logic [7:0] frame_count,
    
    output logic hdmi_tmds_clk_n,
    output logic hdmi_tmds_clk_p,
    output logic [2:0] hdmi_tmds_data_n,
    output logic [2:0] hdmi_tmds_data_p
);

////////////////////////////////////////////////////////
// palette register CDC synchronization

    logic [7:0] palette_sync0, palette_sync1;
    
    always_ff @(posedge clk_25MHz) begin
        if (reset_25MHz) begin
            palette_sync0 <= 8'hE4;
            palette_sync1 <= 8'hE4;
        end
        else begin
            palette_sync0 <= palette;
            palette_sync1 <= palette_sync0;
        end
    end


//////////////////////////////////////////////////////////////////////////////////////////////
// VGA timing controller

    logic [9:0] drawX, drawY;
    logic hsync, vsync, vde;

    vga_controller vga (
        .pixel_clk(clk_25MHz),
        .reset(reset),
        .hs(hsync),
        .vs(vsync),
        .active_nblank(vde),
        .sync(),
        .drawX(drawX),
        .drawY(drawY)
    );
   
///////////////////////////////////////////////////////////////////////////////
// 8-bit unsafe frame counter with asycnhronous active high reset

    counter frame_counter (
        .clk(vsync),
        .reset(reset_axi),
        .count(frame_count)
    );

//////////////////////////////////////////////////////////////////////////////////////////////
// contains 18x20 visible screen tiles labelled with tile IDs

    logic [8:0] vga_map_addr;
    logic [7:0] vga_tile_id;

    // memory-mapped x0000-x01FF
    // only 360 tiles, but 512 for memory alignment
    tilemap_vram tilemap (
        // AXI master R/W Port
        .clka(clk_axi),
        .ena(axi_map_ena),
        .wea(axi_map_we),
        .addra(axi_map_addr),
        .dina(axi_map_wdata),
        .douta(axi_map_rdata),
        // VGA Read Port (always enabled)
        .clkb(clk_25MHz),
        .addrb(vga_map_addr),
        .web(1'b0),
        .dinb(8'h00),
        .doutb(vga_tile_id)
    );
    
//////////////////////////////////////////////////////////////////////////////////////////////
// contains tile data corresponding to IDs

    logic [11:0] vga_tile_addr;
    logic [7:0] vga_tile_data;

    // memory-mapped x2000-x2FFF
    tiledata_vram tiledata (
        // AXI master R/W Port
        .clka(clk_axi),
        .ena(axi_tile_ena),
        .wea(axi_tile_we),
        .addra(axi_tile_addr),
        .dina(axi_tile_wdata),
        .douta(axi_tile_rdata),
        // VGA Read Port (always enabled)
        .clkb(clk_25MHz),
        .addrb(vga_tile_addr),
        .web(1'b0),
        .dinb(8'h00),
        .doutb(vga_tile_data)
    );
    
//////////////////////////////////////////////////////////////////////////////////////////////
// drawing pipeline

    logic [7:0] drawX_160_s0, drawY_144_s0;
    logic [2:0] px_s1, px_s2, px_s3, px_s4;
    logic [2:0] py_s1, py_s2;
    logic [1:0] final_pixel;
    
    logic hs_align, vs_align, vde_align, window_align;

    //localparam MAGIC_NUM = 16'd21846;
    localparam Y_START = 10'd24;
    localparam Y_END = 10'd456;

// Extend your signal arrays to match the 5-stage depth
logic [5:0] hs_pipe, vs_pipe, vde_pipe, window_pipe;

    always_ff @(posedge clk_25MHz) begin
        if (reset_25MHz) begin
            drawX_160_s0 <= 8'h00;
            drawY_144_s0 <= 8'h00;
            {px_s1, px_s2, px_s3, px_s4} <= 8'h00;
            {py_s1, py_s2} <= 4'h0;
            final_pixel <= 2'b11;
        end
        else begin
            // STAGE 0: coordinate calculation
            drawX_160_s0 <= drawX[9:2];
            drawY_144_s0 <= (drawY >= Y_START && drawY < Y_END) ? (drawY - Y_START)/3 : 8'h00;
            window_pipe[0] <= (drawY >= Y_START) && (drawY < Y_END);
            {hs_pipe[0], vs_pipe[0], vde_pipe[0]} <= {hsync, vsync, vde};
    
            // STAGE 1: map addressing
            vga_map_addr <= ((drawY_144_s0 >> 3) * 20) + (drawX_160_s0 >> 3);
            px_s1 <= drawX_160_s0[2:0];
            py_s1 <= drawY_144_s0[2:0];
            {hs_pipe[1], vs_pipe[1], vde_pipe[1], window_pipe[1]} <= {hs_pipe[0], vs_pipe[0], vde_pipe[0], window_pipe[0]};
    
            // STAGE 2: holding for tile id
            px_s2 <= px_s1;
            py_s2 <= py_s1;
            {hs_pipe[2], vs_pipe[2], vde_pipe[2], window_pipe[2]} <= {hs_pipe[1], vs_pipe[1], vde_pipe[1], window_pipe[1]};
    
            // STAGE 3: tile addressing
            vga_tile_addr <= (vga_tile_id << 4) + (py_s2 << 1) + (px_s2 >> 2);
            px_s3 <= px_s2;
            {hs_pipe[3], vs_pipe[3], vde_pipe[3], window_pipe[3]} <= {hs_pipe[2], vs_pipe[2], vde_pipe[2], window_pipe[2]};
    
            // STAGE 4: holding for row byte
            px_s4 <= px_s3;
            {hs_pipe[4], vs_pipe[4], vde_pipe[4], window_pipe[4]} <= {hs_pipe[3], vs_pipe[3], vde_pipe[3], window_pipe[3]};
    
            // STAGE 5: pixel selection
            unique case (px_s4[1:0])
                2'b00 : final_pixel <= vga_tile_data[1:0];
                2'b01 : final_pixel <= vga_tile_data[3:2];
                2'b10 : final_pixel <= vga_tile_data[5:4];
                2'b11 : final_pixel <= vga_tile_data[7:6];
            endcase
            {hs_align, vs_align, vde_align, window_align} <= {hs_pipe[4], vs_pipe[4], vde_pipe[4], window_pipe[4]};
        end
    end
    
//////////////////////////////////////////////////////////////////////////////////////////////
// 4 color mapper

    logic [3:0] red, green, blue;

    color_mapper color_inst (
        .pixel_id(final_pixel),
        .palette(palette_sync1),
        .in_window(window_align && vde_align),
        .red(red),
        .green(green),
        .blue(blue)
    );
    
//////////////////////////////////////////////////////////////////////////////////////////////
// HDMI encoder

    hdmi_tx_0 vga_to_hdmi (
        .pix_clk(clk_25MHz),
        .pix_clkx5(clk_125MHz),
        .pix_clk_locked(1'b1),
        .rst(reset),
        
        .red(red),
        .green(green),
        .blue(blue),
        
        .hsync(hs_align),
        .vsync(vs_align),
        .vde(vde_align),
        
        .aux0_din(4'h0),
        .aux1_din(4'h0),
        .aux2_din(4'h0),
        .ade(1'b0),
        
        .TMDS_CLK_P(hdmi_tmds_clk_p),
        .TMDS_CLK_N(hdmi_tmds_clk_n),
        .TMDS_DATA_P(hdmi_tmds_data_p),
        .TMDS_DATA_N(hdmi_tmds_data_n)
    );
        
endmodule