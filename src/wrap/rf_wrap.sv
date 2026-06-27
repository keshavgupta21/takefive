`include "common.svh"

module rf_wrap (
    input  logic        clk,

    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,
    output logic [31:0] rval1,
    output logic [31:0] rval2,

    input  logic [4:0]  rfwb_rd,
    input  logic        rfwb_wen,
    input  logic [31:0] rfwb_wdata
);

    takefive_pkg::rvals_t rvals;

    takefive_pkg::rfwb_t rfwb;
    assign rfwb.rd    = rfwb_rd;
    assign rfwb.wen   = rfwb_wen;
    assign rfwb.wdata = rfwb_wdata;

    rf u_rf
    (
        .clk   (clk  ),
        .rs1   (rs1  ),
        .rs2   (rs2  ),
        .rvals (rvals),
        .rfwb  (rfwb )
    );

    assign rval1 = rvals.rval1;
    assign rval2 = rvals.rval2;

endmodule
