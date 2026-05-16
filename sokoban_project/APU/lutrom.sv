module lutrom #(
    parameter WIDTH = 8,
    parameter DEPTH = 65536,
    parameter string INIT_FILE = ""
)(
    input logic clk,
    input logic ena,
    input logic [$clog2(DEPTH)-1:0] addr,
    output logic [WIDTH-1:0] dout
);

    (* rom_style = "distributed" *) logic [WIDTH-1:0] mem [DEPTH];
    
    always_ff @(posedge clk) begin
        if (ena) begin
            dout <= mem[addr];
        end
    end
    
    // ROM Initialization
    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end else begin
            // Default: clear memory if no file is provided
            for (int i = 0; i < DEPTH; i++) begin
                mem[i] = {WIDTH{1'b0}};
            end
        end
    end
    
endmodule
