`include "common.svh"

module fetch_wrap #(
    parameter DEPTH = 64
)(
    input  logic        clk,
    input  logic        rst,

    input  logic [31:0] wr_addr,
    input  logic [31:0] wr_data,
    input  logic        wr_en,

    output logic        f_vld,
    output logic [31:0] f_pc,
    output logic [31:0] f_inst,

    input  logic        annul_annul,
    input  logic [31:0] annul_pc,
    input  logic [31:0] annul_nxt_pc,

    input  logic        dbg_pause
);

    takefive_pkg::mem_req_t fetch_req;
    takefive_pkg::mem_req_t mem_req;
    takefive_pkg::mem_rsp_t mem_rsp;

    takefive_pkg::annul_t annul;
    assign annul.annul  = annul_annul;
    assign annul.pc     = annul_pc;
    assign annul.nxt_pc = annul_nxt_pc;

    takefive_pkg::f2d_t f2d;

    fetch #(.DEBUG_EN(1)) u_fetch(
        .clk       (clk       ),
        .rst       (rst       ),
        .mem_req   (fetch_req ),
        .mem_rsp   (mem_rsp   ),
        .f2d       (f2d       ),
        .annul     (annul     ),
        .stall     (1'b0      ),
        .dbg_pause (dbg_pause )
    );

    assign f_vld  = f2d.vld;
    assign f_pc   = f2d.pc;
    assign f_inst = f2d.inst;

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

    block_mem #(.DEPTH(DEPTH)) u_mem(
        .clk (clk     ),
        .rst (rst     ),
        .req (mem_req ),
        .rsp (mem_rsp )
    );

endmodule
