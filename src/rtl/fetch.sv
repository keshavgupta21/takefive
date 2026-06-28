`include "common.svh"

module fetch (
    input  logic                   clk,
    input  logic                   rst,

    output takefive_pkg::mem_req_t mem_req,
    input  takefive_pkg::mem_rsp_t mem_rsp,
    input  logic                   mem_rdy,

    output takefive_pkg::f2d_t     f2d,

    input  takefive_pkg::annul_t   annul,
    input  logic                   stall,

    input  logic                   dbg_pause
);

    logic [31:0] pc, nxt_pc;

    always_comb begin
        if (annul.annul)            nxt_pc = annul.nxt_pc;
        else if (mem_rdy && !stall) nxt_pc = pc + 32'd4;
        else                        nxt_pc = pc;
    end

    always_ff @(posedge clk) begin
        if (rst)                          pc <= '0;
        else if (!dbg_pause) pc <= nxt_pc;
    end

    assign mem_req.vld  = mem_rdy && (!dbg_pause);
    assign mem_req.addr = nxt_pc;
    assign mem_req.wen  = 1'b0;
    assign mem_req.data = 32'b0;

    logic invalidate_rd;
    always_ff @(posedge clk) begin
        if (rst)                          invalidate_rd <= 0;
        else if (annul.annul && !mem_rdy) invalidate_rd <= 1;
        else if (mem_rsp.vld)             invalidate_rd <= 0;
    end

    assign f2d.vld  = mem_rsp.vld && !invalidate_rd;
    assign f2d.pc   = mem_rsp.addr;
    assign f2d.inst = mem_rsp.data;
endmodule
