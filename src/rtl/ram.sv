`include "common.svh"

// DistRAM instantiation template from Xilinx
module ram #(
    parameter WIDTH = 16,
    parameter DEPTH = 64
)(
    input  logic                      clk,
    input  logic                      we,
    input  logic [$clog2(DEPTH)-1:0]  a,
    input  logic [$clog2(DEPTH)-1:0]  dpra,
    input  logic [WIDTH-1:0]          di,
    output logic [WIDTH-1:0]          dpo
);

    // Memory
    logic [WIDTH-1:0] mem [0:DEPTH-1];

    // Write
    always_ff @(posedge clk) begin
        if (we) mem[a] <= di;
    end

    // Ignored wr-port read
    logic [WIDTH-1:0] spo;
    assign spo = mem[a];

    // Read
    assign dpo = mem[dpra];

endmodule
