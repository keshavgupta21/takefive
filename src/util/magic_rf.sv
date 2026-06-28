`include "common.svh"

module magic_rf (
    input  logic                       clk,

    input  takefive_pkg::rf_rd_req_t   rf_rd_req,
    output takefive_pkg::rf_rd_rsp_t   rf_rd_rsp,

    input  takefive_pkg::rf_wr_req_t   rf_wr_req,

    input  logic [4:0]                 dbg_rd_rs,
    output logic [31:0]                dbg_rd_val,

    input  takefive_pkg::rf_wr_req_t   dbg_wr_req
);

    logic [31:0] regs [0:31];

    assign rf_rd_rsp.rval1 = (rf_rd_req.rs1 == 5'b0) ? 32'b0 : regs[rf_rd_req.rs1];
    assign rf_rd_rsp.rval2 = (rf_rd_req.rs2 == 5'b0) ? 32'b0 : regs[rf_rd_req.rs2];
    assign dbg_rd_val      = (dbg_rd_rs     == 5'b0) ? 32'b0 : regs[dbg_rd_rs];

    always_ff @(posedge clk) begin
        if (rf_wr_req.wen && rf_wr_req.rd != 5'b0) regs[rf_wr_req.rd] <= rf_wr_req.wdata;
        if (dbg_wr_req.wen && dbg_wr_req.rd != 5'b0) regs[dbg_wr_req.rd] <= dbg_wr_req.wdata;
    end

endmodule
