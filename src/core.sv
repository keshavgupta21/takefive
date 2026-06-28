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

    // ---------------- Fetch ----------------
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

    // ---------------- Decode ----------------
    takefive_pkg::d2r_t d2r;

    dec u_dec(
        .f2d (f2d),
        .d2r (d2r)
    );

    // ---------------- Debug ----------------
    logic [4:0] rf_rs1, rf_rs2;
    takefive_pkg::rfwb_t rfwb, rfwb_mux;
    always_comb begin
        if (DEBUG_EN && dbg_pause) begin
            rf_rs2         = dbg_rs;
            rfwb_mux.rd    = dbg_rf_rd;
            rfwb_mux.wen   = dbg_rf_wr;
            rfwb_mux.wdata = dbg_rf_data;
        end else begin
            rf_rs2   = d2r.inst.rs2;
            rfwb_mux = rfwb;
        end
        rf_rs1 = d2r.inst.rs1;
    end

    takefive_pkg::rvals_t rvals;
    assign dbg_rval = rvals.rval2;
    assign dbg_pc   = f2d.pc;

    // ---------------- RegFile ----------------
    rf u_rf(
        .clk   (clk         ),
        .rs1   (rf_rs1      ),
        .rs2   (rf_rs2      ),
        .rvals (rvals        ),
        .rfwb  (rfwb_mux     )
    );

    takefive_pkg::r2e_t r2e;
    assign r2e.pc    = d2r.pc;
    assign r2e.inst  = d2r.inst;
    assign r2e.rvals = rvals;

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

endmodule
