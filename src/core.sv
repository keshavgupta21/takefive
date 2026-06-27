`include "common.svh"

module core #(
    parameter DEBUG_EN = 0
)(
    input  logic                   clk,
    input  logic                   rst,

    output takefive_pkg::mem_req_t imem_req,
    input  takefive_pkg::mem_rsp_t imem_rsp,

    input  logic                   dbg_pause,
    input  logic [4:0]             dbg_rs,
    output logic [31:0]            dbg_pc,
    output logic [31:0]            dbg_rval
);

    logic [31:0]          f_pc;
    logic [31:0]          f_inst;
    logic [31:0]          d_pc;
    takefive_pkg::inst_t  d_inst;
    takefive_pkg::rvals_t  rvals;
    takefive_pkg::rfwb_t   rfwb;
    takefive_pkg::nxt_pc_t nxt_pc;

    fetch #(.DEBUG_EN(DEBUG_EN)) u_fetch(
        .clk       (clk      ),
        .rst       (rst      ),
        .mem_req   (imem_req ),
        .mem_rsp   (imem_rsp ),
        .f_pc      (f_pc     ),
        .f_inst    (f_inst   ),
        .nxt_pc    (nxt_pc   ),
        .dbg_pause (dbg_pause)
    );

    dec u_dec(
        .f_pc   (f_pc  ),
        .f_inst (f_inst),
        .d_pc   (d_pc  ),
        .d_inst (d_inst)
    );

    logic [4:0] rf_rs2;

    generate
        if (DEBUG_EN) begin : g_dbg
            assign rf_rs2   = dbg_pause ? dbg_rs : d_inst.rs2;
            assign dbg_rval = rvals.rval2;
            assign dbg_pc   = f_pc;
        end else begin : g_nodbg
            assign rf_rs2   = d_inst.rs2;
            assign dbg_rval = 32'b0;
            assign dbg_pc   = 32'b0;
        end
    endgenerate

    rf #(.DEBUG_EN(DEBUG_EN)) u_rf(
        .clk       (clk       ),
        .rs1       (d_inst.rs1),
        .rs2       (rf_rs2    ),
        .rvals     (rvals     ),
        .rfwb      (rfwb      ),
        .dbg_pause (dbg_pause )
    );

    exe u_exe(
        .pc    (d_pc  ),
        .inst  (d_inst),
        .rvals (rvals ),
        .rfwb  (rfwb  )
    );

    branch u_branch(
        .pc     (d_pc  ),
        .inst   (d_inst),
        .rvals  (rvals ),
        .nxt_pc (nxt_pc)
    );

endmodule
