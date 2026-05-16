module counter (
    input logic clk,
    input logic reset,
    output logic [7:0] count
);

    logic [7:0] count_next;
    
    always_ff @(posedge clk or posedge reset)
    begin
        if (reset)
            count <= '0;
        else
            count <= count_next;
    end
    
    always_comb
    begin
        count_next = count+1;
    end
    
endmodule
