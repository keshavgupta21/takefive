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

    input  logic        dbg_pause,
    input  logic [4:0]  dbg_rf_rd_rs,
    output logic [31:0] dbg_pc,
    output logic [31:0] dbg_rf_rd_val,
    output logic        dbg_commit,
    output logic        dbg_pipe_busy,

    input  logic        dbg_rf_wr_en,
    input  logic [4:0]  dbg_rf_wr_rd,
    input  logic [31:0] dbg_rf_wr_data
);

    takefive_pkg::dram_req_t imem_dram_req;
    takefive_pkg::dram_rsp_t imem_dram_rsp;
    logic                    imem_dram_rdy;

    takefive_pkg::dram_req_t dmem_dram_req;
    takefive_pkg::dram_rsp_t dmem_dram_rsp;
    logic                    dmem_dram_rdy;

    takefive_pkg::rf_rd_req_t rf_rd_req;
    takefive_pkg::rf_rd_rsp_t rf_rd_rsp;
    takefive_pkg::rf_wr_req_t rf_wr_req;

    core u_core(
        .clk           (clk           ),
        .rst           (rst           ),
        .imem_dram_req (imem_dram_req ),
        .imem_dram_rsp (imem_dram_rsp ),
        .imem_dram_rdy (imem_dram_rdy ),
        .dmem_dram_req (dmem_dram_req ),
        .dmem_dram_rsp (dmem_dram_rsp ),
        .dmem_dram_rdy (dmem_dram_rdy ),
        .rf_rd_req     (rf_rd_req     ),
        .rf_rd_rsp     (rf_rd_rsp     ),
        .rf_wr_req     (rf_wr_req     ),
        .dbg_pause     (dbg_pause     ),
        .dbg_pc        (dbg_pc        ),
        .dbg_commit    (dbg_commit    ),
        .dbg_pipe_busy (dbg_pipe_busy )
    );

    takefive_pkg::rf_wr_req_t dbg_rf_wr;
    assign dbg_rf_wr.rd    = dbg_rf_wr_rd;
    assign dbg_rf_wr.wen   = dbg_rf_wr_en;
    assign dbg_rf_wr.wdata = dbg_rf_wr_data;

    magic_rf u_rf(
        .clk        (clk           ),
        .rf_rd_req  (rf_rd_req     ),
        .rf_rd_rsp  (rf_rd_rsp     ),
        .rf_wr_req  (rf_wr_req     ),
        .dbg_rd_rs  (dbg_rf_rd_rs  ),
        .dbg_rd_val (dbg_rf_rd_val ),
        .dbg_wr_req (dbg_rf_wr     )
    );

    takefive_pkg::mem_req_t imem_dbg_req;
    assign imem_dbg_req.vld  = imem_wr_en;
    assign imem_dbg_req.addr = imem_wr_addr;
    assign imem_dbg_req.wen  = imem_wr_en;
    assign imem_dbg_req.data = imem_wr_data;

    takefive_pkg::mem_req_t dmem_dbg_req;
    assign dmem_dbg_req.vld  = dmem_wr_en;
    assign dmem_dbg_req.addr = dmem_wr_addr;
    assign dmem_dbg_req.wen  = dmem_wr_en;
    assign dmem_dbg_req.data = dmem_wr_data;

    dram_mem u_imem(
        .clk       (clk           ),
        .rst       (rst           ),
        .dbg_pause (dbg_pause     ),
        .dbg_req   (imem_dbg_req  ),
        .dram_req  (imem_dram_req ),
        .dram_rsp  (imem_dram_rsp ),
        .dram_rdy  (imem_dram_rdy )
    );

    dram_mem u_dmem(
        .clk       (clk           ),
        .rst       (rst           ),
        .dbg_pause (dbg_pause     ),
        .dbg_req   (dmem_dbg_req  ),
        .dram_req  (dmem_dram_req ),
        .dram_rsp  (dmem_dram_rsp ),
        .dram_rdy  (dmem_dram_rdy )
    );

endmodule
