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
    output logic                   dbg_commit,

    input  logic                   dbg_rf_wr,
    input  logic [4:0]             dbg_rf_rd,
    input  logic [31:0]            dbg_rf_data
);

    //         --- PIPELINE STAGE 1 ---
    // ---------------- Fetch ----------------
    // (fetch output is flopped)
    takefive_pkg::f2d_t    f2d;
    takefive_pkg::nxt_pc_t nxt_pc;

    fetch #(.DEBUG_EN(DEBUG_EN)) u_fetch(
        .clk       (clk      ),
        .rst       (rst      ),
        .mem_req   (imem_req ),
        .mem_rsp   (imem_rsp ),
        .f2d       (f2d      ),
        .nxt_pc    (nxt_pc   ),
        .dbg_pause (dbg_pause)
    );

    //         --- PIPELINE STAGE 2 ---
    // ---------------- Decode ----------------
    takefive_pkg::d2r_t d2r;

    dec u_dec(
        .f2d (f2d),
        .d2r (d2r)
    );

    // ---------------- RegFile ----------------
    takefive_pkg::rvals_t rvals;
    takefive_pkg::rfwb_t  rfwb;

    rf #(.DEBUG_EN(DEBUG_EN)) u_rf(
        .clk         (clk         ),
        .rs1         (d2r.inst.rs1),
        .rs2         (d2r.inst.rs2),
        .rvals       (rvals       ),
        .rfwb        (rfwb        ),
        .dbg_pause   (dbg_pause   ),
        .dbg_rs      (dbg_rs      ),
        .dbg_rval    (dbg_rval    ),
        .dbg_rf_wr   (dbg_rf_wr   ),
        .dbg_rf_rd   (dbg_rf_rd   ),
        .dbg_rf_data (dbg_rf_data )
    );

    takefive_pkg::r2e_t r2e;
    always_ff @(posedge clk) begin
        r2e.vld   <= d2r.vld;
        r2e.pc    <= d2r.pc;
        r2e.inst  <= d2r.inst;
        r2e.rvals <= rvals;
    end

    // ---------------- Exec ----------------
    mem u_mem(
        .r2e     (r2e     ),
        .mem_req (dmem_req)
    );

    exe u_exe(
        .r2e      (r2e     ),
        .dmem_rsp (dmem_rsp),
        .rfwb     (rfwb    )
    );

    branch u_branch(
        .r2e    (r2e   ),
        .nxt_pc (nxt_pc)
    );

    assign dbg_pc     = r2e.pc;
    assign dbg_commit = r2e.vld;
endmodule
