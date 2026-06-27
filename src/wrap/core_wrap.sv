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

    takefive_pkg::mem_req_t core_imem_req;
    takefive_pkg::mem_req_t imem_req;
    takefive_pkg::mem_rsp_t imem_rsp;

    takefive_pkg::mem_req_t core_dmem_req;
    takefive_pkg::mem_rsp_t core_dmem_rsp;

    core #(.DEBUG_EN(1)) u_core(
        .clk       (clk          ),
        .rst       (rst          ),
        .imem_req  (core_imem_req),
        .imem_rsp  (imem_rsp     ),
        .dmem_req  (core_dmem_req),
        .dmem_rsp  (core_dmem_rsp),
        .dbg_pause (dbg_pause    ),
        .dbg_rs    (dbg_rs       ),
        .dbg_pc    (dbg_pc       ),
        .dbg_rval  (dbg_rval     )
    );

    always_comb begin
        if (wr_en) begin
            imem_req.vld  = 1'b1;
            imem_req.addr = wr_addr;
            imem_req.wen  = 1'b1;
            imem_req.data = wr_data;
        end else begin
            imem_req = core_imem_req;
        end
    end

    magic_mem #(.DEPTH(DEPTH)) u_imem(
        .clk (clk     ),
        .req (imem_req),
        .rsp (imem_rsp)
    );

    magic_mem #(.DEPTH(DEPTH)) u_dmem(
        .clk (clk          ),
        .req (core_dmem_req),
        .rsp (core_dmem_rsp)
    );

endmodule
