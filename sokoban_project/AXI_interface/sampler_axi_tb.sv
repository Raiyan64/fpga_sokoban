// Modified testbench from Prof Cheng

//`define SIM_VIDEO //Comment out to simulate AXI bus only

module sampler_axi_tb();

	//clock and reset_n signals
	logic aclk =1'b0;
	logic arstn = 1'b0;
	
	//Write Address channel (AW)
	logic [31:0] write_addr =32'd0;	//Master write address
	logic [2:0] write_prot = 3'd0;	//type of write(leave at 0)
	logic write_addr_valid = 1'b0;	//master indicating address is valid
	logic write_addr_ready;		    //slave ready to receive address

	//Write Data Channel (W)
	logic [31:0] write_data = 32'd0;	//Master write data
	logic [3:0] write_strb = 4'd0;	    //Master byte-wise write strobe
	logic write_data_valid = 1'b0;	    //Master indicating write data is valid
	logic write_data_ready;		        //slave ready to receive data

	//Write Response Channel (WR)
	logic write_resp_ready = 1'b0;	//Master ready to receive write response
	logic [1:0] write_resp;		    //slave write response
	logic write_resp_valid;		    //slave response valid
	
	//Read Address channel (AR)
	logic [31:0] read_addr = 32'd0;	//Master read address
	logic [2:0] read_prot =3'd0;	//type of read(leave at 0)
	logic read_addr_valid = 1'b0;	//Master indicating address is valid
	logic read_addr_ready;		    //slave ready to receive address

	//Read Data Channel (R)
	logic read_data_ready = 1'b0;	//Master indicating ready to receive data
	logic [31:0] read_data;		    //slave read data
	logic [1:0] read_resp;		    //slave read response
	logic read_data_valid;		    //slave indicating data in channel is valid

    //Although we can look at the HDMI signal, it is not particularly useful for debugging
    //Instead, simulate and record the pixel clock and the pixel RGB values to generate
    //a simulated image
    logic [3:0] pixel_rgb [3];
    logic pixel_clk, pixel_hs, pixel_vs, pixel_vde;
    logic [9:0] drawX, drawY;
    logic [31:0] tb_read;
    
    //BMP writer related signals    
    localparam BMP_WIDTH  = 800;
    localparam BMP_HEIGHT = 525;
    logic [23:0] bitmap [BMP_WIDTH][BMP_HEIGHT];

    integer i,j; //use integers for loop indices, etc
    

	//Instantiation of DUT (HDMI TEXT_CONTROLLER) IP
	sampler_interface_top # (
		.DATA_WIDTH(32),
		.ADDR_WIDTH(14)
	) sampler_inst (

		.axi_aclk(aclk),
		.axi_aresetn(arstn),

		.axi_awaddr(write_addr),
		.axi_awprot(write_prot),
		.axi_awvalid(write_addr_valid),
		.axi_awready(write_addr_ready),

		.axi_wdata(write_data),
		.axi_wstrb(write_strb),
		.axi_wvalid(write_data_valid),
		.axi_wready(write_data_ready),

		.axi_bresp(write_resp),
		.axi_bvalid(write_resp_valid),
		.axi_bready(write_resp_ready),

		.axi_araddr(read_addr),
		.axi_arprot(read_prot),
		.axi_arvalid(read_addr_valid),
		.axi_arready(read_addr_ready),

		.axi_rdata(read_data),
		.axi_rresp(read_resp),
		.axi_rvalid(read_data_valid),
		.axi_rready(read_data_ready)
	);
	
	initial begin: CLOCK_INITIALIZATION
	   aclk = 1'b1;
    end 
       
    always begin : CLOCK_GENERATION
        #5 aclk = ~aclk;
    end
    
    // Red Green and Blue values respectively - these come from your draw logic
    assign pixel_rgb[0] = sampler_inst.renderer.red;
    assign pixel_rgb[1] = sampler_inst.renderer.green;
    assign pixel_rgb[2] = sampler_inst.renderer.blue;
    
    // Pixel clock, hs, vs, and vde (!blank) - these come from your internal VGA module
    assign pixel_clk = sampler_inst.renderer.clk_25MHz;
    assign pixel_hs =  sampler_inst.renderer.hsync;
    assign pixel_vs =  sampler_inst.renderer.vsync;
    assign pixel_vde = sampler_inst.renderer.vde;
    
    // DrawX and DrawY - these come from your internal VGA module
    assign drawX = sampler_inst.renderer.drawX;
    assign drawY = sampler_inst.renderer.drawY;
   
    // BMP writing task, based off work from @BrianHGinc:
    // https://github.com/BrianHGinc/SystemVerilog-TestBench-BPM-picture-generator
    task save_bmp(input string bmp_file_name);
        begin
        
            integer unsigned        fout_bmp_pointer, BMP_file_size,BMP_row_size,r;
            logic   unsigned [31:0] BMP_header[0:12];
        
                                      BMP_row_size  = 32'(BMP_WIDTH) & 32'hFFFC;  // When saving a bitmap, the row size/width must be
        if ((BMP_WIDTH & 32'd3) !=0)  BMP_row_size  = BMP_row_size + 4;           // padded to chunks of 4 bytes.
    
        fout_bmp_pointer= $fopen(bmp_file_name,"wb");
        if (fout_bmp_pointer==0) begin
            $display("Could not open file '%s' for writing",bmp_file_name);
            $stop;     
        end
        $display("Saving bitmap '%s'.",bmp_file_name);
       
        BMP_header[0:12] = '{BMP_file_size,0,0054,40,BMP_WIDTH,BMP_HEIGHT,{16'd24,16'd8},0,(BMP_row_size*BMP_HEIGHT*3),2835,2835,0,0};
        
        //Write header out      
        $fwrite(fout_bmp_pointer,"BM");
        for (int i =0 ; i <13 ; i++ ) $fwrite(fout_bmp_pointer,"%c%c%c%c",BMP_header[i][7 -:8],BMP_header[i][15 -:8],BMP_header[i][23 -:8],BMP_header[i][31 -:8]); // Better compatibility with Lattice Active_HDL.
        
        //Write image out (note that image is flipped in Y)
        for (int y=BMP_HEIGHT-1;y>=0;y--) begin
          for (int x=0;x<BMP_WIDTH;x++)
            $fwrite(fout_bmp_pointer,"%c%c%c",bitmap[x][y][23:16],bitmap[x][y][15:8],bitmap[x][y][7:0]) ;
        end
    
        $fclose(fout_bmp_pointer);
        end
    endtask
    
    // Always procedure to log RGB values into array to generate image
    always@(posedge pixel_clk)
        if (!arstn) begin
            for (j = 0; j < BMP_HEIGHT; j++)    //assign bitmap default to some light gray so we 
                for (i = 0; i < BMP_WIDTH; i++) //can tell the difference between drawn black
                    bitmap[i][j] <= 24'h0F0F0F; //and default color
        end
        else
            if (pixel_vde) //Only draw when not in the blanking interval, BMP24 is BGR format
                bitmap[drawX][drawY] <= {pixel_rgb[2], 4'h0, pixel_rgb[1], 4'h0, pixel_rgb[0], 4'h00};

    // Provided AXI write task, follow this example for AXI read below
    task axi_write (input logic [31:0] addr, input logic [31:0] data);
        begin
            #3 write_addr <= addr;	//Put write address on bus
            write_data <= (data << addr[1:0]*8);	//put write data on bus
            write_addr_valid <= 1'b1;	//indicate address is valid
            write_data_valid <= 1'b1;	//indicate data is valid
            write_resp_ready <= 1'b1;	//indicate ready for a response
            write_strb <= (4'h1 << addr[1:0]); //writing all 4 bytes
    
            //wait for one slave ready signal or the other
            wait(write_data_ready || write_addr_ready);
                
            @(posedge aclk); //one or both signals and a positive edge
            if(write_data_ready&&write_addr_ready)//received both ready signals
            begin
                write_addr_valid<=0;
                write_data_valid<=0;
            end
            else    //wait for the other signal and a positive edge
            begin
                if(write_data_ready)    //case data handshake completed
                begin
                    write_data_valid<=0;
                    wait(write_addr_ready); //wait for address address ready
                end
                        else if(write_addr_ready)   //case address handshake completed
                        begin
                    write_addr_valid<=0;
                            wait(write_data_ready); //wait for data ready
                        end 
                @ (posedge aclk);// complete the second handshake
                write_addr_valid<=0; //make sure both valid signals are deasserted
                write_data_valid<=0;
            end
                
            //both handshakes have occured
            //deassert strobe
            write_strb<=0;
    
            //wait for valid response
            wait(write_resp_valid);
            
            //both handshake signals and rising edge
            @(posedge aclk);
    
            //deassert ready for response
            write_resp_ready<=0;
    
            //end of write transaction
        end
    endtask;

    /*
    //Read Address channel (AR)
	logic [31:0] read_addr = 32'd0;	//Master read address
	logic [2:0] read_prot =3'd0;	//type of read(leave at 0)
	logic read_addr_valid = 1'b0;	//Master indicating address is valid
	logic read_addr_ready;		    //slave ready to receive address

	//Read Data Channel (R)
	logic read_data_ready = 1'b0;	//Master indicating ready to receive data
	logic [31:0] read_data;		    //slave read data
	logic [1:0] read_resp;		    //slave read response
	logic read_data_valid;		    //slave indicating data in channel is valid
    */
    
    task axi_read (input logic [31:0] addr, output logic [31:0] data);
        begin
            // add address, assert valid address, and ready to receive read data
            #3 read_addr <= addr;
            read_addr_valid <= 1'b1;
            read_data_ready <= 1'b1;
    
            // wait for slave address ready signal
            @(posedge aclk);
            wait(read_addr_ready);
            @(posedge aclk);
            read_addr_valid <= 1'b0; //make sure both valid signals are deasserted
                   
            // wait for data from slave
            wait(read_data_valid);
            
            // read the data and deassert data ready signal
            data <= read_data;
            @(posedge aclk);
            read_data_ready <= 1'b0;

            //end of read transaction
        end
    endtask;
    
    // Initial block for test vectors begins below
    initial begin: TEST_VECTORS
        arstn = 0; //reset IP
        repeat (4) @(posedge aclk);
        arstn <= 1;
        
        // checkboard pattern tile map
        for(int k=0; k < 512; k++) begin
            repeat (4) @(posedge aclk) axi_write(32'h0000+k, {24'h000, k[7:0]});
        end
        $display("Done writing tile map");
        
        for (int k = 0;k < 4096; k++) begin
            repeat (4) @(posedge aclk) axi_write(32'h2000+k, {24'h000, (k ^ (k >> 3))});
        end
        $display("Done writing to tile data");
        
        repeat (4) @(posedge aclk) axi_write(32'h3000, {24'h000, 8'b00011011});
        $display("Done writing to palette register");
        
        repeat (4) @(posedge aclk) axi_write(32'h3004, 32'hFFFF);
        $display("Attempted write into frame counter");
        
        for (int k = 0; k < 512; k++) begin
            repeat (4) @(posedge aclk) axi_read(32'h0000+k, tb_read);
            assert(tb_read[7:0] == k[7:0])
                else $error("Tile map mismatch @%h exp=%h got %h", 32'h0000+k, k[7:0], tb_read[7:0]);
        end
        $display("Done reading tile map");
        
        for (int k = 0;k < 4096; k++) begin
            repeat (4) @(posedge aclk) axi_read(32'h2000+k, tb_read);
            assert(tb_read == ((k ^ (k >> 3)) & 32'h00FF))
                else $error("Tile data mismatch @%h exp=%h got %h", 32'h2000+k, (k ^ (k >> 3)) & 32'h00FF, tb_read);
        end
		$display("Done reading tile data");
		
		repeat (4) @(posedge aclk) axi_read(32'h3000, tb_read);
		assert(tb_read[7:0] == 8'b00011011)   
		  else $error("Palette register mismatch exp=%h got %h", 8'b11100100, tb_read);
		$display("Done reading palette register");
		
		repeat (4) @(posedge aclk) axi_read(32'h3004, tb_read);
		assert(tb_read[7:0] != 32'hFFFF)
		  else $error("Wrote into read only frame counter");
		
		//Simulate until VS goes low (indicating a new frame) and write the results
		`ifdef SIM_VIDEO
		wait (~pixel_vs);
		save_bmp ("sampler.bmp");
		`endif
		$finish();
	end
    
endmodule