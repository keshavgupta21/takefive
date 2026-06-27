`include "common.svh"

module core_wrap #(
    parameter DEPTH = 1024
)(
    input  logic        clk,
    input  logic        rst,

    input  logic [31:0] wr_addr,
    input  logic [31:0] wr_data,
    input  logic        wr_en,

    input  logic        dbg_pause,
    input  logic [4:0]  dbg_rs,
    output logic [31:0] dbg_pc,
    output logic [31:0] dbg_rval
);

    takefive_pkg::mem_req_t core_req;
    takefive_pkg::mem_req_t mem_req;
    takefive_pkg::mem_rsp_t mem_rsp;

    core #(.DEBUG_EN(1)) u_core(
        .clk       (clk      ),
        .rst       (rst      ),
        .imem_req  (core_req ),
        .imem_rsp  (mem_rsp  ),
        .dbg_pause (dbg_pause),
        .dbg_rs    (dbg_rs   ),
        .dbg_pc    (dbg_pc   ),
        .dbg_rval  (dbg_rval )
    );

    always_comb begin
        if (dbg_pause) begin
            mem_req.vld  = wr_en;
            mem_req.addr = wr_addr;
            mem_req.wen  = wr_en;
            mem_req.data = wr_data;
        end else begin
            mem_req = core_req;
        end
    end

    magic_mem #(.DEPTH(DEPTH)) u_mem(
        .clk (clk    ),
        .req (mem_req),
        .rsp (mem_rsp)
    );

endmodule
