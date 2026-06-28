`include "common.svh"

module core_wrap #(
    parameter DEPTH = 64
)(
    input  logic        clk,
    input  logic        rst,

    input  logic [31:0] wr_addr,
    input  logic [31:0] wr_data,
    input  logic        wr_en,

    input  logic        dbg_pause,
    input  logic [4:0]  dbg_rs,
    output logic [31:0] dbg_pc,
    output logic [31:0] dbg_rval,
    output logic        dbg_commit,

    input  logic        rf_wr_en,
    input  logic [4:0]  rf_wr_rd,
    input  logic [31:0] rf_wr_data
);

    takefive_pkg::mem_req_t core_imem_req;
    takefive_pkg::mem_req_t imem_req;
    takefive_pkg::mem_rsp_t imem_rsp;

    takefive_pkg::mem_req_t core_dmem_req;
    takefive_pkg::mem_rsp_t core_dmem_rsp;

    core #(.DEBUG_EN(1)) u_core(
        .clk         (clk                    ),
        .rst         (rst                    ),
        .imem_req    (core_imem_req          ),
        .imem_rsp    (imem_rsp               ),
        .dmem_req    (core_dmem_req          ),
        .dmem_rsp    (core_dmem_rsp          ),
        .dbg_pause   (dbg_pause              ),
        .dbg_rs      (dbg_rs                 ),
        .dbg_pc      (dbg_pc                 ),
        .dbg_rval    (dbg_rval               ),
        .dbg_commit  (dbg_commit             ),
        .dbg_rf_wr   (rf_wr_en               ),
        .dbg_rf_rd   (rf_wr_rd               ),
        .dbg_rf_data (rf_wr_data             )
    );

    always_comb begin
        if (dbg_pause) begin
            imem_req.vld  = wr_en;
            imem_req.addr = wr_addr;
            imem_req.wen  = wr_en;
            imem_req.data = wr_data;
        end else begin
            imem_req = core_imem_req;
        end
    end

    block_mem #(.DEPTH(DEPTH)) u_imem(
        .clk (clk     ),
        .rst (rst     ),
        .req (imem_req),
        .rsp (imem_rsp)
    );

    takefive_pkg::mem_req_t dmem_req;
    always_comb begin
        if (dbg_pause) begin
            dmem_req.vld  = wr_en;
            dmem_req.addr = wr_addr;
            dmem_req.wen  = wr_en;
            dmem_req.data = 32'b0;
        end else begin
            dmem_req = core_dmem_req;
        end
    end

    block_mem #(.DEPTH(DEPTH)) u_dmem(
        .clk (clk          ),
        .rst (rst          ),
        .req (dmem_req     ),
        .rsp (core_dmem_rsp)
    );


endmodule
