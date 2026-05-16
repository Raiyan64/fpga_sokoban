module player_top (
    input logic clk,
    input logic reset,
    // pushbuttons for testing
    // input logic pause,
    // input logic switchTrack,
    input logic [7:0] keycode,
    input logic vp_in,
    input logic vn_in,
    output logic spkl,
    output logic spkr
);
    
    
    // Board clk is 100Mhz, using sample rate of 8kHz
    // 100_000_000 / 8000 = 12_500
    localparam DIVIDER = 12500;
    localparam SONG_LENGTH = 65536; //set to number of bytes in song
    
    logic [13:0] timer;
    logic [$clog2(SONG_LENGTH)-1:0] sample_addr;
    
    logic [7:0] rawSignal, sample_reg;
    logic [7:0] current_sample;
    logic [7:0] sample1, sample2, sample3;

    typedef enum logic [1:0] {
        SONG1 = 2'b00,
        SONG2 = 2'b01,
        SONG3 = 2'b10
    } song_t;

    song_t songSel;
    
    logic reset_sh;
    logic audio_out;
    
    // prev signals for edge detection
    logic pauseActive;
    logic [7:0] prev_keycode;
    logic [7:0] keycode_sync1, keycode_sync2;
    logic new_key;
    assign new_key = (keycode_sync2 != 8'h00) && (keycode_sync2 != prev_keycode);

    assign spkl = audio_out;
    assign spkr = audio_out;

//////////////////////////////////////////////////////////
// keycode synchronization

    always_ff @(posedge clk) begin
        if (reset_sh) begin
            keycode_sync1 <= 8'h00;
            keycode_sync2 <= 8'h00;
        end
        else begin
            keycode_sync1 <= keycode;
            keycode_sync2 <= keycode_sync1;
        end
    end

    
//////////////////////////////////////////////////////////////////////////////////
// 3 8-bit chiptune music ROM sampled at 8kHz for about 8 seconds each

    track1_rom music1 (
        .clka(clk),
        .ena(1'b1),
        .addra(sample_addr),
        .douta(sample1)
    );
    
    lutrom #(
        .WIDTH(8),
        .DEPTH(SONG_LENGTH),
        .INIT_FILE("underwater2.mem")
    ) music2 (
        .clk(clk),
        .ena(1'b1),
        .addr(sample_addr),
        .dout(sample2)
    );
    
    track3_rom music3 (
        .clka(clk),
        .ena(1'b1),
        .addra(sample_addr),
        .douta(sample3)
    );
    
///////////////////////////////////////////////////////////////////////
// pushbutton debouncer

    sync_debounce reset_sync (
        .clk(clk),
        .d(reset),
        .q(reset_sh)
    );
    
/*
    used for testing

    sync_debounce pause_sync (
        .clk(clk),
        .d(pause),
        .q(pause_sh)
    );
    
    sync_debounce switch_sync (
        .clk(clk),
        .d(switchTrack),
        .q(switchSong)
    );
*/
    
//////////////////////////////////////////////////////////////////////////////////
// song select MUX
    
    mux_4_1 #(.WIDTH(8)) pickSong (
        .a(sample1),
        .b(sample2),
        .c(sample3),
        .d(), // only 3 samples
        .sel(songSel),
        .out(rawSignal)
    );

    always_ff @(posedge clk) begin
        if (reset_sh) begin
            sample_reg <= 8'h00;
        end
        else begin
            sample_reg <= rawSignal;
        end
    end
    
//////////////////////////////////////////////////////////////////////////////////
// Volume controller adjusted by potentiometer

    volume_controller_xadc pot_volume (
        .clk(clk),
        .reset(reset_sh),
        .raw_sample(sample_reg),
        .out_sample(current_sample),
        .vp_in(vp_in),
        .vn_in(vn_in)
    );
    
//////////////////////////////////////////////////////////////////////////////////
// Pulse width pulse for audio output

    pwm_audio pwm_inst (
        .clk(clk),
        .reset(reset_sh),
        .duty_cycle(current_sample),
        .pwm_out(audio_out)
    );

///////////////////////////////////////////////////////////////////////////////////
// switching logic

    always_ff @(posedge clk) begin
        if (reset_sh) begin
            timer <= 14'd0;
            sample_addr <= '0;
            songSel <= SONG1;
            prev_keycode <= 8'h00; 
            pauseActive <= 1'b0;
        end
        else begin
            prev_keycode <= keycode_sync2;
            
            if (new_key) begin
                unique case (keycode_sync2)
                    8'h13 : begin // HID key 'P'
                        pauseActive <= ~pauseActive;
                    end
                    8'h1E : begin // HID key '1'
                        songSel <= SONG1;
                        sample_addr <= '0;
                        timer <= 14'd0;
                    end
                    8'h1F : begin // HID key '2'
                        songSel <= SONG2;
                        sample_addr <= '0;
                        timer <= 14'd0;
                    end
                    8'h20 : begin // HID key '3'
                        songSel <= SONG3;
                        sample_addr <= '0;
                        timer <= 14'd0;
                    end
                    default : ;
                endcase
            end
            
            if (pauseActive) begin end
            else begin
                if (timer >= DIVIDER - 1) begin
                    timer <= 14'd0;
                    if (sample_addr >= SONG_LENGTH - 1) begin
                        sample_addr <= '0;
                    end
                    else begin
                        sample_addr <= sample_addr + 1;
                    end
                end
                else begin
                    timer <= timer + 1;
                end
            end
        end   
    end
    
endmodule