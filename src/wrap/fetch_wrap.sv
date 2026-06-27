`include "common.svh"

module fetch_wrap #(
    parameter DEPTH = 1024
)(
    input  logic        clk,
    input  logic        rst,

    input  logic [31:0] wr_addr,
    input  logic [31:0] wr_data,
    input  logic        wr_en,

    output logic        f_vld,
    output logic [31:0] f_pc,
    output logic [31:0] f_inst,

    input  logic        nxt_pc_vld,
    input  logic [31:0] nxt_pc_pc,
    input  logic [31:0] nxt_pc_nxt_pc,

    input  logic        dbg_pause
);

    takefive_pkg::mem_req_t fetch_req;
    takefive_pkg::mem_req_t mem_req;
    takefive_pkg::mem_rsp_t mem_rsp;

    takefive_pkg::nxt_pc_t nxt_pc;
    assign nxt_pc.vld    = nxt_pc_vld;
    assign nxt_pc.pc     = nxt_pc_pc;
    assign nxt_pc.nxt_pc = nxt_pc_nxt_pc;

    takefive_pkg::fetch_t fetch;

    fetch #(.DEBUG_EN(1)) u_fetch(
        .clk       (clk      ),
        .rst       (rst      ),
        .mem_req   (fetch_req),
        .mem_rsp   (mem_rsp  ),
        .fetch     (fetch    ),
        .nxt_pc    (nxt_pc   ),
        .dbg_pause (dbg_pause)
    );

    assign f_vld  = fetch.vld;
    assign f_pc   = fetch.pc;
    assign f_inst = fetch.inst;

    always_comb begin
        if (dbg_pause) begin
            mem_req.vld  = wr_en;
            mem_req.addr = wr_addr;
            mem_req.wen  = wr_en;
            mem_req.data = wr_data;
        end else begin
            mem_req = fetch_req;
        end
    end

    magic_mem #(.DEPTH(DEPTH)) u_mem(
        .clk (clk    ),
        .req (mem_req),
        .rsp (mem_rsp)
    );

endmodule
