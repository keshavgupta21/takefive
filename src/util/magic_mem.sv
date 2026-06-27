`include "common.svh"

module magic_mem #(
    parameter DEPTH = 1024
)(
    input  logic                   clk,
    input  takefive_pkg::mem_req_t req,
    output takefive_pkg::mem_rsp_t rsp
);

    localparam AWIDTH = $clog2(DEPTH);

    logic [31:0] mem [0:DEPTH-1];

    wire [AWIDTH-1:0] idx = req.addr[AWIDTH+1:2];

    assign rsp.vld  = req.vld;
    assign rsp.addr = req.addr;
    assign rsp.data = mem[idx];

    always_ff @(posedge clk) begin
        if (req.vld && req.wen) mem[idx] <= req.data;
    end

endmodule
