//////////////////////////////////////////////////////////////////////////////////
// modified from ECE385 Prof Cheng

`timescale 1 ns / 1 ps

module sampler_axi_interface # (
    // Width of S_AXI data bus
    parameter integer DATA_WIDTH = 32,
    // Width of S_AXI address bus
    parameter integer ADDR_WIDTH = 14
) (
    // VRAM ports
    // x0000-x01FF
    output logic [8:0] map_addr,
    output logic [7:0] map_wdata,
    output logic map_ena,
    output logic map_we,
    input logic [7:0] map_rdata,

    // x2000-x2FFF
    output logic [11:0] tile_addr,
    output logic [7:0] tile_wdata,
    output logic tile_ena,
    output logic tile_we,
    input logic [7:0] tile_rdata,
    
    // x3000
    output logic [(DATA_WIDTH/4)-1:0] palette_reg,
    
    // x3004 (read-only)
    input logic [(DATA_WIDTH/4)-1:0] frame_count,
    
    // Global Clock Signal
    input logic S_AXI_ACLK,
    // Global Reset Signal. This Signal is Active LOW
    input logic S_AXI_ARESETN,
    // Write address (issued by master, acceped by Slave)
    input logic [ADDR_WIDTH-1:0] S_AXI_AWADDR,
    // Write channel Protection type. This signal indicates the
      // privilege and security level of the transaction, and whether
      // the transaction is a data access or an instruction access.
    input logic [2:0] S_AXI_AWPROT,
    // Write address valid. This signal indicates that the master signaling
      // valid write address and control information.
    input logic S_AXI_AWVALID,
    // Write address ready. This signal indicates that the slave is ready
      // to accept an address and associated control signals.
    output logic S_AXI_AWREADY,
    // Write data (issued by master, acceped by Slave) 
    input logic [DATA_WIDTH-1:0] S_AXI_WDATA,
    // Write strobes. This signal indicates which byte lanes hold
      // valid data. There is one write strobe bit for each eight
      // bits of the write data bus.    
    input logic [(DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    // Write valid. This signal indicates that valid write
      // data and strobes are available.
    input logic S_AXI_WVALID,
    // Write ready. This signal indicates that the slave
      // can accept the write data.
    output logic S_AXI_WREADY,
    // Write response. This signal indicates the status
      // of the write transaction.
    output logic [1:0] S_AXI_BRESP,
    // Write response valid. This signal indicates that the channel
      // is signaling a valid write response.
    output logic S_AXI_BVALID,
    // Response ready. This signal indicates that the master
      // can accept a write response.
    input logic S_AXI_BREADY,
    // Read address (issued by master, acceped by Slave)
    input logic [ADDR_WIDTH-1:0] S_AXI_ARADDR,
    // Protection type. This signal indicates the privilege
      // and security level of the transaction, and whether the
      // transaction is a data access or an instruction access.
    input logic [2:0] S_AXI_ARPROT,
    // Read address valid. This signal indicates that the channel
      // is signaling valid read address and control information.
    input logic S_AXI_ARVALID,
    // Read address ready. This signal indicates that the slave is
      // ready to accept an address and associated control signals.
    output logic S_AXI_ARREADY,
    // Read data (issued by slave)
    output logic [DATA_WIDTH-1:0] S_AXI_RDATA,
    // Read response. This signal indicates the status of the
      // read transfer.
    output logic [1:0] S_AXI_RRESP,
    // Read valid. This signal indicates that the channel is
      // signaling the required read data.
    output logic S_AXI_RVALID,
    // Read ready. This signal indicates that the master can
      // accept the read data and response information.
    input logic S_AXI_RREADY
);
    
    // AXI4LITE signals
    logic [ADDR_WIDTH-1:0] axi_awaddr;
    logic axi_awready;
    logic axi_wready;
    logic [1:0] axi_bresp;
    logic axi_bvalid;
    logic [ADDR_WIDTH-1:0] axi_araddr;
    logic axi_arready;
    logic [DATA_WIDTH-1:0] axi_rdata;
    logic [1:0] axi_rresp;
    logic axi_rvalid;
    
    // I/O Connections assignments
    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY	= axi_wready;
    assign S_AXI_BRESP = axi_bresp;
    assign S_AXI_BVALID	= axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA = axi_rdata;
    assign S_AXI_RRESP = axi_rresp;
    assign S_AXI_RVALID = axi_rvalid;

    logic rd_handshake, wr_handshake;
    logic [DATA_WIDTH-1:0] reg_data_out;
    logic aw_en;

///////////////////////////////////////////////////////////////////

     // memory mapped x3000
    logic [(DATA_WIDTH/4)-1:0] palette;
    assign palette_reg = palette;

    logic sel_map_w, sel_tile_w, sel_palette_w;
    logic sel_map_r, sel_tile_r, sel_palette_r, sel_frame_r;

    assign sel_map_w = (axi_awaddr < 14'h0200);
    assign sel_tile_w = (axi_awaddr >= 14'h2000) && (axi_awaddr < 14'h3000);
    assign sel_palette_w = (axi_awaddr == 14'h3000);

    assign sel_map_r = (axi_araddr < 14'h0200);
    assign sel_tile_r = (axi_araddr >= 14'h2000) && (axi_araddr < 14'h3000);
    assign sel_palette_r = (axi_araddr == 14'h3000);
    assign sel_frame_r = (axi_araddr == 14'h3004);

    logic [ADDR_WIDTH-1:0] vram_addr_eff;
    logic [(DATA_WIDTH/4)-1:0] vram_wbyte;

///////////////////////////////////////////////////////////////////

    logic write_delay;

    // Implement axi_awready generation
    // axi_awready is asserted for one S_AXI_ACLK clock cycle when both
    // S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
    // de-asserted when reset is low.
    
    always_ff @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_awready <= 1'b0;
            aw_en <= 1'b1;
        end 
        else begin    
            if (!axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
                // slave is ready to accept write address when 
                // there is a valid write address and write data
                // on the write address and data bus. This design 
                // expects no outstanding transactions. 
                axi_awready <= 1'b1;
                aw_en <= 1'b0;
            end
            else if (S_AXI_BREADY && axi_bvalid) begin
                aw_en <= 1'b1;
                axi_awready <= 1'b0;
            end
            else begin
                axi_awready <= 1'b0;
            end
        end 
    end
    
    // Implement axi_awaddr latching
    // This process is used to latch the address when both 
    // S_AXI_AWVALID and S_AXI_WVALID are valid. 
    
    always_ff @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_awaddr <= '0;
        end 
        else begin    
            if (!axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
                // Write Address latching 
                axi_awaddr <= S_AXI_AWADDR;
            end
        end 
    end       
    
    // Implement axi_wready generation
    // axi_wready is asserted for one S_AXI_ACLK clock cycle when both
    // S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
    // de-asserted when reset is low. 
    
    always_ff @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_wready <= 1'b0;
        end 
        else begin    
            if (!axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en) begin
                // slave is ready to accept write data when 
                // there is a valid write address and write data
                // on the write address and data bus. This design 
                // expects no outstanding transactions. 
                axi_wready <= 1'b1;
            end
            else begin
                axi_wready <= 1'b0;
            end
        end 
    end       
    
    // Implement memory mapped register select and write logic generation
    // The write data is accepted and written to memory mapped registers when
    // axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
    // select byte enables of slave registers while writing.
    // These registers are cleared when reset (active low) is applied.
    // Slave register write enable is asserted when valid address and data are available
    // and the slave is ready to accept the write address and write data.
    
    assign wr_handshake = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

    always_comb begin
        vram_wbyte = '0;

        if (wr_handshake) begin
            priority casez (S_AXI_WSTRB)
                4'b???1 : begin
                    vram_wbyte = S_AXI_WDATA[7:0];
                end
                4'b??10 : begin
                    vram_wbyte = S_AXI_WDATA[15:8];
                end
                4'b?100 : begin
                    vram_wbyte = S_AXI_WDATA[23:16];
                end
                4'b1000 : begin
                    vram_wbyte = S_AXI_WDATA[31:24];
                end
                default : begin
                    vram_wbyte = '0;
                end
            endcase
        end
    end

    always_ff @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            // enable is reset in another ff block
            map_we <= 1'b0;
            tile_we <= 1'b0;
            map_wdata <= 8'h00;
            tile_wdata <= 8'h00;
            palette <= 8'hE4;
        end
        else begin
            map_we <= 1'b0;
            tile_we <= 1'b0;
            
            if (wr_handshake && (|S_AXI_WSTRB)) begin                
                if (sel_map_w) begin
                    map_wdata <= vram_wbyte;
                    map_we <= 1'b1;
                end
                else if (sel_tile_w) begin
                    tile_wdata <= vram_wbyte;
                    tile_we <= 1'b1;
                end
                else if (sel_palette_w) begin
                    palette <= vram_wbyte;
                end
            end     
        end
    end
    
    // Implement write response logic generation
    // The write response and response valid signals are asserted by the slave 
    // when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
    // This marks the acceptance of address and indicates the status of 
    // write transaction.
    
    always_ff @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_bvalid <= 1'b0;
            axi_bresp <= 2'b00;
            write_delay <= 1'b0;
        end 
        else begin
            write_delay <= wr_handshake;
            // if waited enough after awready and wready signals are asserted
            if (write_delay) begin
                // indicates a valid write response is available
                axi_bvalid <= 1'b1;
                axi_bresp <= 2'b00; // 'OKAY' response 
            end                   // work error responses in future
            else begin
                if (S_AXI_BREADY && axi_bvalid) begin
                //check if bready is asserted while bvalid is high 
                //(there is a possibility that bready is always asserted high)   
                axi_bvalid <= 1'b0; 
                end  
            end
        end
    end

///////////////////////////////////////////////////////////////////
    
    // Implement axi_arready generation
    // axi_arready is asserted for one S_AXI_ACLK clock cycle when
    // S_AXI_ARVALID is asserted. axi_awready is 
    // de-asserted when reset (active low) is asserted. 
    // The read address is also latched when S_AXI_ARVALID is 
    // asserted. axi_araddr is reset to zero on reset assertion.
    
    always_ff @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_arready <= 1'b0;
            axi_araddr <= '0;
        end 
        else begin    
            if (!axi_arready && S_AXI_ARVALID) begin
                // indicates that the slave has acceped the valid read address
                axi_arready <= 1'b1;
                // Read address latching
                axi_araddr <= S_AXI_ARADDR;
            end
            else begin
                axi_arready <= 1'b0;
            end
        end
    end

    logic read_delay, read_delay_2;
    
    // Implement axi_arvalid generation
    // axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
    // S_AXI_ARVALID and axi_arready are asserted. The slave registers 
    // data are available on the axi_rdata bus at this instance. The 
    // assertion of axi_rvalid marks the validity of read data on the 
    // bus and axi_rresp indicates the status of read transaction.axi_rvalid 
    // is deasserted on reset (active low). axi_rresp and axi_rdata are 
    // cleared to zero on reset (active low).  
    always_ff @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_rvalid <= 1'b0;
            axi_rresp <= 2'b00;
            read_delay <= 1'b0;
            read_delay_2 <= 1'b0;
        end 
        else begin
            read_delay <= rd_handshake;
            read_delay_2 <= read_delay;

            // add delay for reading
            if (read_delay_2) begin
                // Valid read data is available at the read data bus
                axi_rvalid <= 1'b1;
                axi_rresp <= 2'b00; // 'OKAY' response
            end   
            else if (axi_rvalid && S_AXI_RREADY) begin
                // Read data is accepted by the master
                axi_rvalid <= 1'b0;
            end                
        end
    end    
    
    // Implement memory mapped register select and read logic generation
    // Slave register read enable is asserted when valid address is available
    // and the slave is ready to accept the read address.
    
    assign rd_handshake = axi_arready && S_AXI_ARVALID && !axi_rvalid;
    
    always_comb begin
        if (sel_map_r)
            reg_data_out = {24'd0, map_rdata};
        else if (sel_tile_r)
            reg_data_out = {24'd0, tile_rdata};
        else if (sel_palette_r) begin
            reg_data_out = {24'd0, palette};
        end
        else if (sel_frame_r) begin
            reg_data_out = {24'd0, frame_count};
        end
        else begin
            reg_data_out = '0;
        end
    end
    
    // Output register or memory read data
    always_ff @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_rdata <= '0;
        end 
        else begin    
            // When there is a valid read address (S_AXI_ARVALID) with 
            // acceptance of read address by the slave (axi_arready), 
            // put read data on AXI read channel
            if (read_delay_2) begin
                axi_rdata <= reg_data_out;
            end       
        end
    end

//////////////////////////////////////////////////////////////////////
// unified address

    always_comb begin
        if (wr_handshake && (sel_map_w || sel_tile_w))
            vram_addr_eff = axi_awaddr;
        else
            vram_addr_eff = axi_araddr;
    end

    always_ff @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            map_ena <= 1'b0;
            tile_ena <= 1'b0;
            map_addr <= '0;
            tile_addr <= '0;
        end
        else begin
            map_ena <= (wr_handshake && sel_map_w) || (rd_handshake && sel_map_r);
            tile_ena <= (wr_handshake && sel_tile_w) || (rd_handshake && sel_tile_r);
            map_addr <= vram_addr_eff[8:0];
            tile_addr <= vram_addr_eff[11:0];
        end
    end
    
endmodule