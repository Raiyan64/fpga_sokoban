module mux_4_1 #(
    parameter WIDTH = 8
)(
    input logic[WIDTH-1 : 0] a,
    input logic [WIDTH-1 : 0] b,
    input logic [WIDTH-1 : 0] c,
    input logic [WIDTH-1 : 0] d,
    input logic [1:0] sel,
    output logic [WIDTH-1 : 0] out
);

always_comb begin

    unique case (sel)
        2'b00 : out = a;
        2'b01 : out = b;
        2'b10 : out = c;
        2'b11 : out = d;
        default : out = 0;
    endcase

end

endmodule