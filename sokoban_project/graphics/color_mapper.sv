module color_mapper (
    input logic [1:0] pixel_id,
    input logic [7:0] palette,
    input logic in_window,
    output logic [3:0] red, green, blue
);

    logic [1:0] pixel_data;
    
    always_comb begin
        case (pixel_id)
            2'b00 : pixel_data = palette[1:0];
            2'b01 : pixel_data = palette[3:2];
            2'b10 : pixel_data = palette[5:4];
            2'b11 : pixel_data = palette[7:6];
        endcase
    end
    
    always_comb begin
        if (!in_window) begin
            red = 4'h0;
            green = 4'h0;
            blue = 4'h0;
        end
        else begin
            case (pixel_data)
                2'b00 : begin // lighest green
                    red = 4'hB;
                    green = 4'hF;
                    blue = 4'hA;
                end
                2'b01 : begin
                    red = 4'h7;
                    green = 4'h9;
                    blue = 4'h7;
                end
                2'b10 : begin
                    red = 4'h3;
                    green = 4'h6;
                    blue = 4'h3;
                end
                2'b11 : begin // darkest green
                    red = 4'h0;
                    green = 4'h3;
                    blue = 4'h0;
                end
            endcase
        end
    end

endmodule