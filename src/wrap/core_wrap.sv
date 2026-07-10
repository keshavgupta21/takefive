`include "common.svh"

module core_wrap (
    input  logic        clk,
    input  logic        rst,

    input  logic [31:0] imem_wr_addr,
    input  logic [31:0] imem_wr_data,
    input  logic        imem_wr_en,

    input  logic [31:0] dmem_wr_addr,
    input  logic [31:0] dmem_wr_data,
    input  logic        dmem_wr_en,

    output logic        dbg_pause,
    output logic [31:0] dbg_pc,
    output logic        dbg_commit,
    output logic        dbg_pipe_busy,

    input  logic [7:0]  s_mmio_araddr,
    input  logic [2:0]  s_mmio_arprot,
    input  logic        s_mmio_arvalid,
    output logic        s_mmio_arready,

    output logic [31:0] s_mmio_rdata,
    output logic [1:0]  s_mmio_rresp,
    output logic        s_mmio_rvalid,
    input  logic        s_mmio_rready,

    input  logic [7:0]  s_mmio_awaddr,
    input  logic [2:0]  s_mmio_awprot,
    input  logic        s_mmio_awvalid,
    output logic        s_mmio_awready,

    input  logic [31:0] s_mmio_wdata,
    input  logic [3:0]  s_mmio_wstrb,
    input  logic        s_mmio_wvalid,
    output logic        s_mmio_wready,

    output logic [1:0]  s_mmio_bresp,
    output logic        s_mmio_bvalid,
    input  logic        s_mmio_bready,

    output logic        m_axis_tvalid,
    input  logic        m_axis_tready,
    output logic [31:0] m_axis_tdata,

    input  logic        s_axis_tvalid,
    output logic        s_axis_tready,
    input  logic [31:0] s_axis_tdata,
    input  logic [31:0] s_axis_level
);

    takefive_pkg::dram_req_t imem_dram_req;
    takefive_pkg::dram_rsp_t imem_dram_rsp;
    logic                    imem_dram_rdy;

    takefive_pkg::dram_req_t dmem_dram_req;
    takefive_pkg::dram_rsp_t dmem_dram_rsp;
    logic                    dmem_dram_rdy;

    core u_core(
        .clk            (clk            ),
        .rst            (rst            ),
        .imem_dram_req  (imem_dram_req  ),
        .imem_dram_rsp  (imem_dram_rsp  ),
        .imem_dram_rdy  (imem_dram_rdy  ),
        .dmem_dram_req  (dmem_dram_req  ),
        .dmem_dram_rsp  (dmem_dram_rsp  ),
        .dmem_dram_rdy  (dmem_dram_rdy  ),
        .dbg_pause      (dbg_pause      ),
        .dbg_pc         (dbg_pc         ),
        .dbg_commit     (dbg_commit     ),
        .dbg_pipe_busy  (dbg_pipe_busy  ),
        .s_mmio_araddr  (s_mmio_araddr  ),
        .s_mmio_arprot  (s_mmio_arprot  ),
        .s_mmio_arvalid (s_mmio_arvalid ),
        .s_mmio_arready (s_mmio_arready ),
        .s_mmio_rdata   (s_mmio_rdata   ),
        .s_mmio_rresp   (s_mmio_rresp   ),
        .s_mmio_rvalid  (s_mmio_rvalid  ),
        .s_mmio_rready  (s_mmio_rready  ),
        .s_mmio_awaddr  (s_mmio_awaddr  ),
        .s_mmio_awprot  (s_mmio_awprot  ),
        .s_mmio_awvalid (s_mmio_awvalid ),
        .s_mmio_awready (s_mmio_awready ),
        .s_mmio_wdata   (s_mmio_wdata   ),
        .s_mmio_wstrb   (s_mmio_wstrb   ),
        .s_mmio_wvalid  (s_mmio_wvalid  ),
        .s_mmio_wready  (s_mmio_wready  ),
        .s_mmio_bresp   (s_mmio_bresp   ),
        .s_mmio_bvalid  (s_mmio_bvalid  ),
        .s_mmio_bready  (s_mmio_bready  ),
        .m_axis_tvalid  (m_axis_tvalid  ),
        .m_axis_tready  (m_axis_tready  ),
        .m_axis_tdata   (m_axis_tdata   ),
        .s_axis_tvalid  (s_axis_tvalid  ),
        .s_axis_tready  (s_axis_tready  ),
        .s_axis_tdata   (s_axis_tdata   ),
        .s_axis_level   (s_axis_level   )
    );

    takefive_pkg::mem_req_t imem_dbg_req;
    assign imem_dbg_req.vld  = imem_wr_en;
    assign imem_dbg_req.wen  = imem_wr_en;
    assign imem_dbg_req.addr = imem_wr_addr;
    assign imem_dbg_req.data = imem_wr_data;
    assign imem_dbg_req.uid  = '0;

    takefive_pkg::mem_req_t dmem_dbg_req;
    assign dmem_dbg_req.vld  = dmem_wr_en;
    assign dmem_dbg_req.wen  = dmem_wr_en;
    assign dmem_dbg_req.addr = dmem_wr_addr;
    assign dmem_dbg_req.data = dmem_wr_data;
    assign dmem_dbg_req.uid  = '0;

    dram_mem #(.BASE(32'h00000000)) u_imem(
        .clk       (clk           ),
        .rst       (rst           ),
        .dbg_pause (dbg_pause     ),
        .dbg_req   (imem_dbg_req  ),
        .dram_req  (imem_dram_req ),
        .dram_rsp  (imem_dram_rsp ),
        .dram_rdy  (imem_dram_rdy )
    );

    dram_mem #(.BASE(32'h80000000)) u_dmem(
        .clk       (clk           ),
        .rst       (rst           ),
        .dbg_pause (dbg_pause     ),
        .dbg_req   (dmem_dbg_req  ),
        .dram_req  (dmem_dram_req ),
        .dram_rsp  (dmem_dram_rsp ),
        .dram_rdy  (dmem_dram_rdy )
    );

endmodule
