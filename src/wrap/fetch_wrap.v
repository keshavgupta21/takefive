`include "common.svh"

module fetch_wrap (
    input  wire        clk,
    input  wire        rst,

    input  wire [31:0] wr_addr,
    input  wire [31:0] wr_data,
    input  wire        wr_en,

    output wire        f_vld,
    output wire [31:0] f_pc,
    output wire [31:0] f_inst,

    input  wire        annul_annul,
    input  wire [31:0] annul_pc,
    input  wire [31:0] annul_nxt_pc,

    input  wire        dbg_pause
);

    takefive_pkg::mem_req_t mem_req;
    takefive_pkg::mem_rsp_t mem_rsp;

    takefive_pkg::annul_t annul;
    assign annul.annul  = annul_annul;
    assign annul.pc     = annul_pc;
    assign annul.nxt_pc = annul_nxt_pc;

    takefive_pkg::f2d_t f2d;

    wire mem_rdy;

    fetch u_fetch(
        .clk       (clk       ),
        .rst       (rst       ),
        .mem_req   (mem_req   ),
        .mem_rsp   (mem_rsp   ),
        .mem_rdy   (mem_rdy   ),
        .f2d       (f2d       ),
        .annul     (annul     ),
        .stall     (!f2d.vld  ),
        .dbg_pause (dbg_pause )
    );

    assign f_vld  = f2d.vld;
    assign f_pc   = f2d.pc;
    assign f_inst = f2d.inst;

    takefive_pkg::mem_req_t dbg_req;
    assign dbg_req.vld  = wr_en;
    assign dbg_req.wen  = wr_en;
    assign dbg_req.addr = wr_addr;
    assign dbg_req.data = wr_data;
    assign dbg_req.uid  = '0;

    delay_mem u_mem(
        .clk       (clk       ),
        .rst       (rst       ),
        .dbg_pause (dbg_pause ),
        .dbg_req   (dbg_req   ),
        .mem_req   (mem_req   ),
        .mem_rsp   (mem_rsp   ),
        .mem_rdy   (mem_rdy   )
    );

endmodule
