`include "common.svh"

module icache_wrap (
    input  logic        clk,
    input  logic        rst,

    input  logic        dbg_pause,
    input  logic [31:0] wr_addr,
    input  logic [31:0] wr_data,
    input  logic        wr_en,

    input  logic        mem_req_vld,
    input  logic [31:0] mem_req_addr,

    output logic        mem_rsp_vld,
    output logic [31:0] mem_rsp_addr,
    output logic [31:0] mem_rsp_data,
    output logic        mem_rdy
);

    takefive_pkg::mem_req_t mem_req;
    assign mem_req.vld  = mem_req_vld;
    assign mem_req.addr = mem_req_addr;
    assign mem_req.wen  = 1'b0;
    assign mem_req.data = 32'b0;

    takefive_pkg::mem_rsp_t mem_rsp;
    assign mem_rsp_vld  = mem_rsp.vld;
    assign mem_rsp_addr = mem_rsp.addr;
    assign mem_rsp_data = mem_rsp.data;

    takefive_pkg::dram_req_t dram_req;
    takefive_pkg::dram_rsp_t dram_rsp;
    logic                    dram_rdy;

    icache u_icache(
        .clk      (clk      ),
        .rst      (rst      ),
        .mem_req  (mem_req  ),
        .mem_rsp  (mem_rsp  ),
        .mem_rdy  (mem_rdy  ),
        .dram_req (dram_req ),
        .dram_rsp (dram_rsp ),
        .dram_rdy (dram_rdy )
    );

    takefive_pkg::mem_req_t dbg_req;
    assign dbg_req.vld  = wr_en;
    assign dbg_req.addr = wr_addr;
    assign dbg_req.wen  = wr_en;
    assign dbg_req.data = wr_data;

    dram_mem u_dram(
        .clk       (clk       ),
        .rst       (rst       ),
        .dbg_pause (dbg_pause ),
        .dbg_req   (dbg_req   ),
        .dram_req  (dram_req  ),
        .dram_rsp  (dram_rsp  ),
        .dram_rdy  (dram_rdy  )
    );

endmodule
