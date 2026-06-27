`include "common.svh"

module fetch_wrap #(
    parameter DEPTH = 1024
)(
    input  logic        clk,
    input  logic        rst,

    input  logic [31:0] wr_addr,
    input  logic [31:0] wr_data,
    input  logic        wr_en,

    output logic [31:0] f_pc,
    output logic [31:0] f_inst
);

    takefive_pkg::mem_req_t fetch_req;
    takefive_pkg::mem_req_t mem_req;
    takefive_pkg::mem_rsp_t mem_rsp;

    fetch u_fetch
    (
        .clk     (clk      ),
        .rst     (rst      ),
        .mem_req (fetch_req),
        .mem_rsp (mem_rsp  ),
        .f_pc    (f_pc     ),
        .f_inst  (f_inst   )
    );

    always_comb begin
        if (wr_en) begin
            mem_req.vld  = 1'b1;
            mem_req.addr = wr_addr;
            mem_req.wen  = 1'b1;
            mem_req.data = wr_data;
        end else begin
            mem_req = fetch_req;
        end
    end

    magic_mem #(.DEPTH(DEPTH)) u_mem
    (
        .clk (clk    ),
        .req (mem_req),
        .rsp (mem_rsp)
    );

endmodule
