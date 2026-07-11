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

    input  takefive_pkg::dram_req_t imem_dram_req,
    output takefive_pkg::dram_rsp_t imem_dram_rsp,
    output logic                    imem_dram_rdy,

    input  takefive_pkg::dram_req_t dmem_dram_req,
    output takefive_pkg::dram_rsp_t dmem_dram_rsp,
    output logic                    dmem_dram_rdy,

    input  logic                    dbg_prog,
    output logic                    dbg_pause,

    `s_axil_intf                   (mmio),
    `m_axis_intf                   (axis),
    `s_axis_intf                   (axis),
    `m_axi_intf                    (imem_axi),
    `m_axi_intf                    (dmem_axi)
    );

    // ---- imem passthrough ----

    assign imem_cache_req = imem_pipe_req;
    assign imem_pipe_rsp  = imem_cache_rsp;
    assign imem_pipe_rdy  = imem_cache_rdy;

    // ---- MMIO decode ----

    logic       is_mmio;
    logic [5:0] word   ;
    logic       mmio_wr;
    logic       mmio_rd;
    assign is_mmio = (dmem_pipe_req.addr[31:8] == 24'hFFFFFF);
    assign word    = dmem_pipe_req.addr[7:2];
    assign mmio_wr = dmem_pipe_req.vld && is_mmio &&  dmem_pipe_req.wen;
    assign mmio_rd = dmem_pipe_req.vld && is_mmio && !dmem_pipe_req.wen;

    // ---- dbg_pause ----

    logic dbg_stop_core;

    always_ff @(posedge clk) begin
        if (rst) dbg_stop_core <= 1'b0;
        else if (mmio_wr && word == takefive_pkg::MMIO_ADDR_EXIT[7:2]) dbg_stop_core <= 1'b1;
    end

    assign dbg_pause = dbg_stop_core | dbg_prog;

    // ---- AXI Stream master ----

    assign m_axis_tvalid = mmio_wr && word == takefive_pkg::MMIO_ADDR_STREAM[7:2];
    assign m_axis_tdata  = dmem_pipe_req.data;

    // ---- AXI Stream slave ----

    assign s_axis_tready = mmio_rd && word == takefive_pkg::MMIO_ADDR_STREAM[7:2];

    // ---- MMIO distributed RAM ----

    logic  [4:0] saxil_raddr;
    logic [31:0] saxil_rdata;

    ram #(.WIDTH(32), .DEPTH(32)) u_mmio_ram(
        .clk  (clk                         ),
        .we   (mmio_wr && word < takefive_pkg::MMIO_DATA_WORDS[7:2]),
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

    // ---- maxil instances ----

    maxil u_imem_maxil(
        .clk           (clk                ),
        .rst           (rst                ),
        .base          (imem_base          ),
        .bound         (imem_bound         ),
        .dram_req      (imem_dram_req      ),
        .dram_rsp      (imem_dram_rsp      ),
        .dram_rdy      (imem_dram_rdy      ),
        .m_axi_araddr  (m_imem_axi_araddr  ),
        .m_axi_arprot  (m_imem_axi_arprot  ),
        .m_axi_arvalid (m_imem_axi_arvalid ),
        .m_axi_arready (m_imem_axi_arready ),
        .m_axi_rdata   (m_imem_axi_rdata   ),
        .m_axi_rresp   (m_imem_axi_rresp   ),
        .m_axi_rvalid  (m_imem_axi_rvalid  ),
        .m_axi_rready  (m_imem_axi_rready  ),
        .m_axi_awaddr  (m_imem_axi_awaddr  ),
        .m_axi_awprot  (m_imem_axi_awprot  ),
        .m_axi_awvalid (m_imem_axi_awvalid ),
        .m_axi_awready (m_imem_axi_awready ),
        .m_axi_wdata   (m_imem_axi_wdata   ),
        .m_axi_wstrb   (m_imem_axi_wstrb   ),
        .m_axi_wvalid  (m_imem_axi_wvalid  ),
        .m_axi_wready  (m_imem_axi_wready  ),
        .m_axi_bresp   (m_imem_axi_bresp   ),
        .m_axi_bvalid  (m_imem_axi_bvalid  ),
        .m_axi_bready  (m_imem_axi_bready  )
    );

    maxil u_dmem_maxil(
        .clk           (clk                ),
        .rst           (rst                ),
        .base          (dmem_base          ),
        .bound         (dmem_bound         ),
        .dram_req      (dmem_dram_req      ),
        .dram_rsp      (dmem_dram_rsp      ),
        .dram_rdy      (dmem_dram_rdy      ),
        .m_axi_araddr  (m_dmem_axi_araddr  ),
        .m_axi_arprot  (m_dmem_axi_arprot  ),
        .m_axi_arvalid (m_dmem_axi_arvalid ),
        .m_axi_arready (m_dmem_axi_arready ),
        .m_axi_rdata   (m_dmem_axi_rdata   ),
        .m_axi_rresp   (m_dmem_axi_rresp   ),
        .m_axi_rvalid  (m_dmem_axi_rvalid  ),
        .m_axi_rready  (m_dmem_axi_rready  ),
        .m_axi_awaddr  (m_dmem_axi_awaddr  ),
        .m_axi_awprot  (m_dmem_axi_awprot  ),
        .m_axi_awvalid (m_dmem_axi_awvalid ),
        .m_axi_awready (m_dmem_axi_awready ),
        .m_axi_wdata   (m_dmem_axi_wdata   ),
        .m_axi_wstrb   (m_dmem_axi_wstrb   ),
        .m_axi_wvalid  (m_dmem_axi_wvalid  ),
        .m_axi_wready  (m_dmem_axi_wready  ),
        .m_axi_bresp   (m_dmem_axi_bresp   ),
        .m_axi_bvalid  (m_dmem_axi_bvalid  ),
        .m_axi_bready  (m_dmem_axi_bready  )
    );

    // ---- dmem dcache path ----

    always_comb begin
        dmem_cache_req      = dmem_pipe_req;
        dmem_cache_req.vld  = dmem_pipe_req.vld && !is_mmio;
        dmem_cache_req.addr = dmem_pipe_req.addr - takefive_pkg::DMEM_VADDR;
    end

    // ---- MMIO response to pipeline ----

    logic [31:0] mmio_rd_data;
    always_comb begin
        if (word == takefive_pkg::MMIO_ADDR_STREAM[7:2])      mmio_rd_data = s_axis_tdata;
        else if (word == takefive_pkg::MMIO_ADDR_RLEVEL[7:2]) mmio_rd_data = s_axis_level;
        else                                                  mmio_rd_data = 32'h0;
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
