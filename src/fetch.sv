`include "common.svh"

module fetch #(
    parameter DEBUG_EN = 0
)(
    input  logic                   clk,
    input  logic                   rst,

    output takefive_pkg::mem_req_t mem_req,
    input  takefive_pkg::mem_rsp_t mem_rsp,

    output takefive_pkg::f2d_t     f2d,

    input  takefive_pkg::annul_t   annul,

    input  logic                   dbg_pause
);

    logic [31:0] next_pc_val;

    always_comb begin
        if (annul.annul) next_pc_val = annul.nxt_pc;
        else            next_pc_val = f2d.pc + 32'd4;
    end

    assign mem_req.vld  = (!DEBUG_EN || !dbg_pause);
    assign mem_req.addr = next_pc_val;
    assign mem_req.wen  = 1'b0;
    assign mem_req.data = 32'b0;

    always_ff @(posedge clk) begin
        if (rst) begin
            f2d.pc  <= 32'hFFFFFFFC;
            f2d.vld <= 1'b0;
        end else if (!DEBUG_EN || !dbg_pause) begin
            f2d.pc  <= next_pc_val;
            f2d.vld <= 1'b1;
        end
    end

    assign f2d.inst = mem_rsp.data;
endmodule
