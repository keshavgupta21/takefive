`include "common.svh"
module exe (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic [7:0] result
);

    always_ff @(posedge clk) begin
        if (rst)
            result <= 8'h00;
        else
            result <= (a > b) ? a : b;
    end

endmodule
