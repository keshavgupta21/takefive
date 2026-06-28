`include "common.svh"

module fetch #(
    parameter DEBUG_EN = 0
)(
    input  logic                   clk,
    input  logic                   rst,

    output takefive_pkg::mem_req_t mem_req,
    input  takefive_pkg::mem_rsp_t mem_rsp,

    output takefive_pkg::f2d_t   f2d,

    input  takefive_pkg::nxt_pc_t  nxt_pc,

    input  logic                   dbg_pause
);

    logic [31:0] pc;

    always_ff @(posedge clk) begin
        if (rst) pc <= 32'b0;
        else if (!DEBUG_EN || !dbg_pause) begin
            if (nxt_pc.vld) pc <= nxt_pc.nxt_pc;
            else            pc <= pc + 32'd4;
        end
    end

    assign mem_req.vld  = !rst && (!DEBUG_EN || !dbg_pause);
    assign mem_req.addr = pc;
    assign mem_req.wen  = 1'b0;
    assign mem_req.data = 32'b0;

    assign f2d.vld  = !rst && (!DEBUG_EN || !dbg_pause);
    assign f2d.pc   = pc;
    assign f2d.inst = mem_rsp.data;

endmodule
