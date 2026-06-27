`include "common.svh"

module rf_wrap (
    input  logic        clk,

    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,
    output logic [31:0] rval1,
    output logic [31:0] rval2,

    input  logic [4:0]  rd,
    input  logic        wen,
    input  logic [31:0] wdata
);

    rf u_rf (
        .clk   (clk),
        .rs1   (rs1),
        .rs2   (rs2),
        .rval1 (rval1),
        .rval2 (rval2),
        .rd    (rd),
        .wen   (wen),
        .wdata (wdata)
    );

endmodule
