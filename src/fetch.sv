`include "common.svh"

module fetch #(
    parameter DEBUG_EN = 0
)(
    input  logic                   clk,
    input  logic                   rst,

    output takefive_pkg::mem_req_t mem_req,
    input  takefive_pkg::mem_rsp_t mem_rsp,

    output logic [31:0]            f_pc,
    output logic [31:0]            f_inst,

    input  logic                   dbg_pause
);

    logic [31:0] pc;

    generate
        if (DEBUG_EN) begin : g_dbg
            always_ff @(posedge clk) begin
                if (rst)            pc <= 32'b0;
                else if (!dbg_pause) pc <= pc + 32'd4;
            end
        end else begin : g_nodbg
            always_ff @(posedge clk) begin
                if (rst) pc <= 32'b0;
                else     pc <= pc + 32'd4;
            end
        end
    endgenerate

    assign mem_req.vld  = !rst;
    assign mem_req.addr = pc;
    assign mem_req.wen  = 1'b0;
    assign mem_req.data = 32'b0;

    assign f_pc   = pc;
    assign f_inst = mem_rsp.data;

endmodule
