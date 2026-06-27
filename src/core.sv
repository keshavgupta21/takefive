`include "common.svh"
module core (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic [7:0] result
);

    exe u_exe (
        .clk    (clk),
        .rst    (rst),
        .a      (a),
        .b      (b),
        .result (result)
    );

endmodule
