`include "common.svh"

module dec_rf_exe_wrap (
    input  logic        clk,
    input  logic [31:0] f_pc,
    input  logic [31:0] f_inst,

    output logic [4:0]  rfwb_rd,
    output logic        rfwb_wen,
    output logic [31:0] rfwb_wdata
);

    logic [31:0]          d_pc;
    takefive_pkg::inst_t  d_inst;
    takefive_pkg::rvals_t rvals;
    takefive_pkg::rfwb_t  rfwb;

    dec u_dec(
        .f_pc   (f_pc  ),
        .f_inst (f_inst),
        .d_pc   (d_pc  ),
        .d_inst (d_inst)
    );

    rf #(.DEBUG_EN(0)) u_rf(
        .clk       (clk        ),
        .rs1       (d_inst.rs1 ),
        .rs2       (d_inst.rs2 ),
        .rvals     (rvals      ),
        .rfwb      ('0         ),
        .dbg_pause (1'b0       )
    );

    exe u_exe(
        .pc    (d_pc  ),
        .inst  (d_inst),
        .rvals (rvals ),
        .rfwb  (rfwb  )
    );

    assign rfwb_rd    = rfwb.rd;
    assign rfwb_wen   = rfwb.wen;
    assign rfwb_wdata = rfwb.wdata;

endmodule
