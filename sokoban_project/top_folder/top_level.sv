`timescale 1ns / 1ps

module top_level (
    input logic Clk,
    input logic reset,
    /*
    // Pushbuttons for testing
    input logic pause,
    input logic switchTrack,
    */
    // USB SPI signals
    input logic [0:0] gpio_usb_int_tri_i,
    output logic gpio_usb_rst_tri_o,
    input logic usb_spi_miso,
    output logic usb_spi_mosi,
    output logic usb_spi_sclk,
    output logic usb_spi_ss,
    
    // UART signals
    input logic uart_rxd,
    output logic uart_txd,
    
    // HDMI signals
    output logic hdmi_tmds_clk_n,
    output logic hdmi_tmds_clk_p,
    output logic [2:0] hdmi_tmds_data_n,
    output logic [2:0] hdmi_tmds_data_p,
    
    // potentiometer analog inputs
    input logic Vp_P, // analog positive
    input logic Vn_N, // analog negative
    
    // PWM signals
    output logic spkl,
    output logic spkr
    /*
    // HEX display (unused)
    output logic [7:0] hex_segA,
    output logic [3:0] hex_gridA,
    output logic [7:0] hex_segB,
    output logic [3:0] hex_gridB
    */  
);

    logic [31:0] keycode_0, keycode_1;

    mb_block mb_block_0 (
        .HDMI_tmds_clk_n(hdmi_tmds_clk_n),
        .HDMI_tmds_clk_p(hdmi_tmds_clk_p),
        .HDMI_tmds_data_n(hdmi_tmds_data_n),
        .HDMI_tmds_data_p(hdmi_tmds_data_p),
        .clk_100MHz(Clk),
        .gpio_usb_int_tri_i(gpio_usb_int_tri_i),
        .gpio_usb_keycode_0_tri_o(keycode_0),
        .gpio_usb_keycode_1_tri_o(keycode_1),
        .gpio_usb_rst_tri_o(gpio_usb_rst_tri_o),
        .reset_rtl_0(~reset),
        .uart_rtl_0_rxd(uart_rxd),
        .uart_rtl_0_txd(uart_txd),
        .usb_spi_miso(usb_spi_miso),
        .usb_spi_mosi(usb_spi_mosi),
        .usb_spi_sclk(usb_spi_sclk),
        .usb_spi_ss(usb_spi_ss)
    );
    
    player_top chiptune (
        .clk(Clk),
        .reset(reset),
        /*
        .pause(pause),
        .switchTrack(switchTrack),
        */
        .keycode(keycode_0[7:0]),
        .vp_in(Vp_P),
        .vn_in(Vn_N),
        .spkl(spkl),
        .spkr(spkr)
    );
    
endmodule