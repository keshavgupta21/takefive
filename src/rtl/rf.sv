`include "common.svh"

module rf (
    input  logic                      clk,
    input  logic                      rst,

    input  takefive_pkg::rf_rd_req_t  rf_rd_req,
    output takefive_pkg::rf_rd_rsp_t  rf_rd_rsp,

    input  takefive_pkg::rf_wr_req_t  rf_wr_req
);

    logic [4:0]  wr_rd;
    logic        wr_en;
    logic [31:0] wr_data;
    assign wr_rd   = rst ? 5'd0  : rf_wr_req.rd;
    assign wr_en   = rst ? 1'b1  : (rf_wr_req.wen && rf_wr_req.rd != 5'd0);
    assign wr_data = rst ? 32'd0 : rf_wr_req.wdata;

    ram #(.WIDTH(32), .DEPTH(32)) u_rf1(
        .clk  (clk             ),
        .we   (wr_en           ),
        .a    (wr_rd           ),
        .dpra (rf_rd_req.rs1   ),
        .di   (wr_data         ),
        .dpo  (rf_rd_rsp.rval1 )
    );

    ram #(.WIDTH(32), .DEPTH(32)) u_rf2(
        .clk  (clk             ),
        .we   (wr_en           ),
        .a    (wr_rd           ),
        .dpra (rf_rd_req.rs2   ),
        .di   (wr_data         ),
        .dpo  (rf_rd_rsp.rval2 )
    );

endmodule
