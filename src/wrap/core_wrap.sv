`include "common.svh"

module core_wrap #(
    parameter DEPTH = 64
)(
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

    takefive_pkg::mem_req_t imem_req;
    takefive_pkg::mem_rsp_t imem_rsp;

    takefive_pkg::mem_req_t dmem_req;
    takefive_pkg::mem_rsp_t dmem_rsp;

    logic imem_rdy;
    logic dmem_rdy;

    takefive_pkg::rf_rd_req_t rf_rd_req;
    takefive_pkg::rf_rd_rsp_t rf_rd_rsp;
    takefive_pkg::rf_wr_req_t rf_wr_req;

    core u_core(
        .clk           (clk           ),
        .rst           (rst           ),
        .imem_req      (imem_req      ),
        .imem_rsp      (imem_rsp      ),
        .imem_rdy      (imem_rdy      ),
        .dmem_req      (dmem_req      ),
        .dmem_rsp      (dmem_rsp      ),
        .dmem_rdy      (dmem_rdy      ),
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

    delay_mem #(.DEPTH(DEPTH)) u_imem(
        .clk       (clk          ),
        .rst       (rst          ),
        .dbg_pause (dbg_pause    ),
        .dbg_req   (imem_dbg_req ),
        .mem_req   (imem_req     ),
        .mem_rsp   (imem_rsp     ),
        .mem_rdy   (imem_rdy     )
    );

    delay_mem #(.DEPTH(DEPTH)) u_dmem(
        .clk       (clk          ),
        .rst       (rst          ),
        .dbg_pause (dbg_pause    ),
        .dbg_req   (dmem_dbg_req ),
        .mem_req   (dmem_req     ),
        .mem_rsp   (dmem_rsp     ),
        .mem_rdy   (dmem_rdy     )
    );

endmodule
