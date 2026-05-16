module volume_controller_xadc (
    input logic clk,
    input logic reset,
    input logic [7:0] raw_sample,
    output logic [7:0] out_sample,
    input logic vp_in, // wiper voltage
    input logic vn_in // ground voltage
);

    logic [15:0] adc_data;
    logic drdy;
    logic [7:0] volume_reg;
    
    // special IP block for monitoring analog signals, on-chip temperatures, and supply voltages
    // currently configured to read from address 0x03 which is the VP/VN channel
    xadc_wiz_0 pot_volume (
        .dclk_in(clk),
        .reset_in(reset),

        .daddr_in(7'h03), // status register of analog input potentiometer
        .den_in(1'b1), // enable
        .dwe_in(1'b0), // R'/W
        .di_in(16'd0), // data input

        .do_out(adc_data), // data output
        .drdy_out(drdy), // data ready (data valid to read)

        .vp_in(vp_in),
        .vn_in(vn_in),
        
        // unused ports
        .eoc_out(), // pulse when ADC finishes a measurement
        .eos_out(), // pulse when last channel in sequence is converted
        .busy_out(), // ADC busy
        .alarm_out(), // flags for FPGA monitor
        .channel_out() // indicate which analog channel is getting converted
    );
    
    always_ff @(posedge clk) begin
        if (reset) begin
            volume_reg <= 8'h00;
        end
        else if (drdy) begin
            volume_reg <= adc_data[15:8];
        end
    end
    
    logic signed [8:0] centered_sample;
    logic signed [16:0] scaled_sample;
    logic signed [8:0] out_sample_signed;
    
    always_comb begin
        // center the audio
        centered_sample = $signed({1'b0, raw_sample}) - 9'sd128;
        scaled_sample = centered_sample * $signed({1'b0, volume_reg});
        
        // using the top 8 bits works as a gain factor
        out_sample_signed = scaled_sample[16:9];
    end
    
    // add latch for timing
    always_ff @(posedge clk) begin
        if (reset)
            out_sample <= 8'h00;
        else
            out_sample <= unsigned'(out_sample_signed + 9'sd128);
    end
    
endmodule