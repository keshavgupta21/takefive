`include "common.svh"

module core_wrap (
    input  logic        clk,
    input  logic        rst,

    input  logic [31:0] imem_wr_addr,
    input  logic [31:0] imem_wr_data,
    input  logic        imem_wr_en,

    input  logic [31:0] dmem_wr_addr,
    input  logic [31:0] dmem_wr_data,
    input  logic        dmem_wr_en,

    output logic        mmio_req_vld,
    output logic        mmio_req_wen,
    output logic [31:0] mmio_req_addr,
    output logic [31:0] mmio_req_data,
    output logic [31:0] mmio_req_uid,
    input  logic        mmio_rsp_vld,
    input  logic [31:0] mmio_rsp_data,
    input  logic [31:0] mmio_rsp_uid,
    input  logic        mmio_rdy,

    input  logic        dbg_pause,
    output logic [31:0] dbg_pc,
    output logic        dbg_commit,
    output logic        dbg_pipe_busy
);

    takefive_pkg::dram_req_t imem_dram_req;
    takefive_pkg::dram_rsp_t imem_dram_rsp;
    logic                    imem_dram_rdy;

    takefive_pkg::dram_req_t dmem_dram_req;
    takefive_pkg::dram_rsp_t dmem_dram_rsp;
    logic                    dmem_dram_rdy;

    takefive_pkg::mem_req_t mmio_req;
    assign mmio_req_vld  = mmio_req.vld;
    assign mmio_req_wen  = mmio_req.wen;
    assign mmio_req_addr = mmio_req.addr;
    assign mmio_req_data = mmio_req.data;
    assign mmio_req_uid  = mmio_req.uid;

    takefive_pkg::mem_rsp_t mmio_rsp;
    assign mmio_rsp.vld  = mmio_rsp_vld;
    assign mmio_rsp.data = mmio_rsp_data;
    assign mmio_rsp.uid  = mmio_rsp_uid;

    core u_core(
        .clk           (clk           ),
        .rst           (rst           ),
        .imem_dram_req (imem_dram_req ),
        .imem_dram_rsp (imem_dram_rsp ),
        .imem_dram_rdy (imem_dram_rdy ),
        .dmem_dram_req (dmem_dram_req ),
        .dmem_dram_rsp (dmem_dram_rsp ),
        .dmem_dram_rdy (dmem_dram_rdy ),
        .mmio_req      (mmio_req      ),
        .mmio_rsp      (mmio_rsp      ),
        .mmio_rdy      (mmio_rdy      ),
        .dbg_pause     (dbg_pause     ),
        .dbg_pc        (dbg_pc        ),
        .dbg_commit    (dbg_commit    ),
        .dbg_pipe_busy (dbg_pipe_busy )
    );

    takefive_pkg::mem_req_t imem_dbg_req;
    assign imem_dbg_req.vld  = imem_wr_en;
    assign imem_dbg_req.wen  = imem_wr_en;
    assign imem_dbg_req.addr = imem_wr_addr;
    assign imem_dbg_req.data = imem_wr_data;
    assign imem_dbg_req.uid  = '0;

    takefive_pkg::mem_req_t dmem_dbg_req;
    assign dmem_dbg_req.vld  = dmem_wr_en;
    assign dmem_dbg_req.wen  = dmem_wr_en;
    assign dmem_dbg_req.addr = dmem_wr_addr;
    assign dmem_dbg_req.data = dmem_wr_data;
    assign dmem_dbg_req.uid  = '0;

    dram_mem #(.BASE(32'h00000000)) u_imem(
        .clk       (clk           ),
        .rst       (rst           ),
        .dbg_pause (dbg_pause     ),
        .dbg_req   (imem_dbg_req  ),
        .dram_req  (imem_dram_req ),
        .dram_rsp  (imem_dram_rsp ),
        .dram_rdy  (imem_dram_rdy )
    );

    dram_mem #(.BASE(32'h80000000)) u_dmem(
        .clk       (clk           ),
        .rst       (rst           ),
        .dbg_pause (dbg_pause     ),
        .dbg_req   (dmem_dbg_req  ),
        .dram_req  (dmem_dram_req ),
        .dram_rsp  (dmem_dram_rsp ),
        .dram_rdy  (dmem_dram_rdy )
    );

endmodule
