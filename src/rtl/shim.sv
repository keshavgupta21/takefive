`include "common.svh"

module shim (
    input  logic                    clk,
    input  logic                    rst,

    input  takefive_pkg::mem_req_t  imem_pipe_req,
    output takefive_pkg::mem_rsp_t  imem_pipe_rsp,
    output logic                    imem_pipe_rdy,

    output takefive_pkg::mem_req_t  imem_cache_req,
    input  takefive_pkg::mem_rsp_t  imem_cache_rsp,
    input  logic                    imem_cache_rdy,

    input  takefive_pkg::mem_req_t  dmem_pipe_req,
    output takefive_pkg::mem_rsp_t  dmem_pipe_rsp,
    output logic                    dmem_pipe_rdy,

    output takefive_pkg::mem_req_t  dmem_cache_req,
    input  takefive_pkg::mem_rsp_t  dmem_cache_rsp,
    input  logic                    dmem_cache_rdy,

    output logic                    dbg_pause,

    `s_axil_intf(mmio),
    `m_axis_intf(axis),
    `s_axis_intf(axis)
    );

    // ---- imem passthrough ----

    assign imem_cache_req = imem_pipe_req;
    assign imem_pipe_rsp  = imem_cache_rsp;
    assign imem_pipe_rdy  = imem_cache_rdy;

    // ---- MMIO decode ----

    localparam DATA_WORDS  = 6'h20;
    localparam RLEVEL_WORD = 6'h3D;
    localparam PUTC_WORD   = 6'h3E;
    localparam EXIT_WORD   = 6'h3F;

    logic       is_mmio;
    logic [5:0] word   ;
    logic       mmio_wr;
    logic       mmio_rd;
    assign is_mmio = (dmem_pipe_req.addr[31:8] == 24'hFFFFFF);
    assign word    = dmem_pipe_req.addr[7:2];
    assign mmio_wr = dmem_pipe_req.vld && is_mmio &&  dmem_pipe_req.wen;
    assign mmio_rd = dmem_pipe_req.vld && is_mmio && !dmem_pipe_req.wen;

    // ---- dbg_pause register ----

    always_ff @(posedge clk) begin
        if (rst) dbg_pause <= 1'b1;
        else if (mmio_wr && word == EXIT_WORD) dbg_pause <= 1'b1;
        else dbg_pause <= 1'b0;
    end

    // ---- AXI Stream master (putc) ----

    assign m_axis_tvalid = mmio_wr && word == PUTC_WORD;
    assign m_axis_tdata  = dmem_pipe_req.data;

    // ---- AXI Stream slave (getc) ----

    assign s_axis_tready = mmio_rd && word == PUTC_WORD;

    // ---- MMIO distributed RAM ----

    logic  [4:0] saxil_raddr;
    logic [31:0] saxil_rdata;

    ram #(.WIDTH(32), .DEPTH(32)) u_mmio_ram(
        .clk  (clk                         ),
        .we   (mmio_wr && word < DATA_WORDS),
        .a    (dmem_pipe_req.addr[6:2]     ),
        .di   (dmem_pipe_req.data          ),
        .dpra (saxil_raddr                 ),
        .dpo  (saxil_rdata                 )
    );

    // ---- AXI-Lite slave ----

    logic [31:0] imem_base ;
    logic [31:0] imem_bound;
    logic [31:0] dmem_base ;
    logic [31:0] dmem_bound;

    saxil u_saxil(
        .clk           (clk        ),
        .rst           (rst        ),
        `s_axil_passtie(mmio       ),
        .mmio_raddr    (saxil_raddr),
        .mmio_rdata    (saxil_rdata),
        .imem_base     (imem_base  ),
        .imem_bound    (imem_bound ),
        .dmem_base     (dmem_base  ),
        .dmem_bound    (dmem_bound )
    );

    // ---- dmem dcache path ----

    always_comb begin
        dmem_cache_req     = dmem_pipe_req;
        dmem_cache_req.vld = dmem_pipe_req.vld && !is_mmio;
    end

    // ---- MMIO response to pipeline ----

    logic [31:0] mmio_rd_data;
    always_comb begin
        if (word == PUTC_WORD)        mmio_rd_data = s_axis_tdata;
        else if (word == RLEVEL_WORD) mmio_rd_data = s_axis_level;
        else                          mmio_rd_data = 32'h0;
    end

    takefive_pkg::mem_rsp_t mmio_rsp;
    always_ff @(posedge clk) begin
        if (rst) mmio_rsp <= '0;
        else begin
            mmio_rsp.vld  <= dmem_pipe_req.vld && is_mmio;
            mmio_rsp.uid  <= dmem_pipe_req.uid;
            mmio_rsp.data <= mmio_rd_data;
        end
    end

    assign dmem_pipe_rdy = is_mmio ? 1'b1 : dmem_cache_rdy;

    always_comb begin
        if (mmio_rsp.vld) dmem_pipe_rsp = mmio_rsp;
        else              dmem_pipe_rsp = dmem_cache_rsp;
    end

endmodule
