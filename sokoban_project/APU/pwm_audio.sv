module pwm_audio (
    input  logic clk,
    input reset,
    input  logic [7:0] duty_cycle,
    output logic pwm_out
);

    logic [7:0] counter;
    
    always_ff @(posedge clk) begin
        if (reset) begin
            counter <= 8'd0;
            pwm_out <= 1'b0;
        end
        else begin
            counter <= counter + 1;
            pwm_out <= (counter < duty_cycle);
        end
    end

endmodule