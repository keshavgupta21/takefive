`include "common.svh"

module block_mem #(
    parameter DEPTH = 1024
)(
    input  logic                   clk,
    input  logic                   rst,
    input  takefive_pkg::mem_req_t req,
    output takefive_pkg::mem_rsp_t rsp,
    output logic                   mem_rdy
);

    localparam AWIDTH = $clog2(DEPTH);

    (* ram_style = "block" *) logic [31:0] ram [0:DEPTH-1];
    logic [31:0] dout;

    wire [AWIDTH-1:0] idx = req.addr[AWIDTH+1:2];

    always_ff @(posedge clk) begin
        if (req.vld && req.wen) ram[idx] <= req.data;
        dout <= ram[idx];
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            rsp.vld  <= 0;
            rsp.addr <= '0;
        end else begin
            rsp.vld  <= req.vld;
            rsp.addr <= req.addr;
        end
    end

    assign rsp.data = dout;
    assign mem_rdy  = 1'b1;

endmodule
