`include "common.svh"

module rf #(
    parameter DEBUG_EN = 0
)(
    input  logic                 clk,

    input  logic [4:0]           rs1,
    input  logic [4:0]           rs2,
    output takefive_pkg::rvals_t rvals,

    input  takefive_pkg::rfwb_t  rfwb,

    input  logic                 dbg_pause
);
    logic [31:0] regs [0:31];

    initial begin
        regs[0] = 32'b0;
        for (int i = 1; i < 32; i++) regs[i] = 32'h01010101 * i;
    end

    always_ff @(posedge clk) begin
        if (rfwb.wen && rfwb.rd != 5'b0 && (!DEBUG_EN || !dbg_pause)) regs[rfwb.rd] <= rfwb.wdata;
    end

    assign rvals.rval1 = regs[rs1];
    assign rvals.rval2 = regs[rs2];

endmodule
