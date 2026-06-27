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

    dec #(.DEBUG_EN(DEBUG_EN)) u_dec(
        .f_pc      (f_pc     ),
        .f_inst    (f_inst   ),
        .d_pc      (d_pc     ),
        .d_inst    (d_inst   ),
        .dbg_pause (dbg_pause)
    );

    logic [4:0] rf_rs2;
    assign rf_rs2   = (DEBUG_EN && dbg_pause) ? dbg_rs : d_inst.rs2;
    assign dbg_rval = rvals.rval2;
    assign dbg_pc   = f_pc;

    rf #(.DEBUG_EN(DEBUG_EN)) u_rf(
        .clk       (clk       ),
        .rs1       (d_inst.rs1),
        .rs2       (rf_rs2    ),
        .rvals     (rvals     ),
        .rfwb      (rfwb      ),
        .dbg_pause (dbg_pause )
    );

    exe #(.DEBUG_EN(DEBUG_EN)) u_exe(
        .pc        (d_pc     ),
        .inst      (d_inst   ),
        .rvals     (rvals    ),
        .dmem_rsp  (dmem_rsp ),
        .rfwb      (rfwb     ),
        .dbg_pause (dbg_pause)
    );

    mem #(.DEBUG_EN(DEBUG_EN)) u_mem(
        .inst      (d_inst   ),
        .rvals     (rvals    ),
        .mem_req   (dmem_req ),
        .dbg_pause (dbg_pause)
    );

    branch #(.DEBUG_EN(DEBUG_EN)) u_branch(
        .pc        (d_pc     ),
        .inst      (d_inst   ),
        .rvals     (rvals    ),
        .nxt_pc    (nxt_pc   ),
        .dbg_pause (dbg_pause)
    );

endmodule
