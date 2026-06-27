`include "common.svh"

module core #(
    parameter DEBUG_EN = 0
)(
    input  logic                   clk,
    input  logic                   rst,

    output takefive_pkg::mem_req_t imem_req,
    input  takefive_pkg::mem_rsp_t imem_rsp,

    output takefive_pkg::mem_req_t dmem_req,
    input  takefive_pkg::mem_rsp_t dmem_rsp,

    input  logic                   dbg_pause,
    input  logic [4:0]             dbg_rs,
    output logic [31:0]            dbg_pc,
    output logic [31:0]            dbg_rval,

    input  logic                   dbg_rf_wr,
    input  logic [4:0]             dbg_rf_rd,
    input  logic [31:0]            dbg_rf_data
);

    takefive_pkg::fetch_t  f;
    logic [31:0]           d_pc;
    takefive_pkg::inst_t   d_inst;
    takefive_pkg::rvals_t  rvals;
    takefive_pkg::rfwb_t   rfwb;
    takefive_pkg::nxt_pc_t nxt_pc;

    fetch #(.DEBUG_EN(DEBUG_EN)) u_fetch(
        .clk       (clk      ),
        .rst       (rst      ),
        .mem_req   (imem_req ),
        .mem_rsp   (imem_rsp ),
        .fetch     (f        ),
        .nxt_pc    (nxt_pc   ),
        .dbg_pause (dbg_pause)
    );

    dec u_dec(
        .fetch  (f     ),
        .d_pc   (d_pc  ),
        .d_inst (d_inst)
    );

    logic [4:0] rf_rs2;
    takefive_pkg::rfwb_t rf_rfwb;
    always_comb begin
        if (DEBUG_EN && dbg_pause) begin
            rf_rs2        = dbg_rs;
            rf_rfwb.rd    = dbg_rf_rd;
            rf_rfwb.wen   = dbg_rf_wr;
            rf_rfwb.wdata = dbg_rf_data;
        end else begin
            rf_rs2  = d_inst.rs2;
            rf_rfwb = rfwb;
        end
    end

    assign dbg_rval = rvals.rval2;
    assign dbg_pc   = f.pc;

    rf u_rf(
        .clk   (clk       ),
        .rs1   (d_inst.rs1),
        .rs2   (rf_rs2    ),
        .rvals (rvals     ),
        .rfwb  (rf_rfwb   )
    );

    exe u_exe(
        .pc       (d_pc    ),
        .inst     (d_inst  ),
        .rvals    (rvals   ),
        .dmem_rsp (dmem_rsp),
        .rfwb     (rfwb    )
    );

    mem u_mem(
        .inst    (d_inst  ),
        .rvals   (rvals   ),
        .mem_req (dmem_req)
    );

    branch u_branch(
        .pc     (d_pc  ),
        .inst   (d_inst),
        .rvals  (rvals ),
        .nxt_pc (nxt_pc)
    );

endmodule
