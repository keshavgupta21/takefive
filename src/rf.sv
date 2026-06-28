`include "common.svh"

module rf #(
    parameter DEBUG_EN = 0
)(
    input  logic                 clk,

    input  logic [4:0]           rs1,
    input  logic [4:0]           rs2,
    output takefive_pkg::rvals_t rvals,

    input  takefive_pkg::rfwb_t  rfwb,

    input  logic                 dbg_pause,
    input  logic [4:0]           dbg_rs,
    output logic [31:0]          dbg_rval,

    input  logic                 dbg_rf_wr,
    input  logic [4:0]           dbg_rf_rd,
    input  logic [31:0]          dbg_rf_data
);

    logic [4:0]          rs2_mux;
    takefive_pkg::rfwb_t rfwb_mux;

    always_comb begin
        if (DEBUG_EN && dbg_pause) begin
            rs2_mux        = dbg_rs;
            rfwb_mux.rd    = dbg_rf_rd;
            rfwb_mux.wen   = dbg_rf_wr;
            rfwb_mux.wdata = dbg_rf_data;
        end else begin
            rs2_mux  = rs2;
            rfwb_mux = rfwb;
        end
    end
    assign dbg_rval = rvals.rval2;

    // Port 1
    logic [31:0] regs1 [0:31];
    always_ff @(posedge clk) begin
        if (rfwb_mux.wen && rfwb_mux.rd != 5'b0) regs1[rfwb_mux.rd] <= rfwb_mux.wdata;
    end
    assign rvals.rval1 = regs1[rs1];

    // Port 2
    logic [31:0] regs2 [0:31];
    always_ff @(posedge clk) begin
        if (rfwb_mux.wen && rfwb_mux.rd != 5'b0) regs2[rfwb_mux.rd] <= rfwb_mux.wdata;
    end
    assign rvals.rval2 = regs2[rs2_mux];

endmodule
