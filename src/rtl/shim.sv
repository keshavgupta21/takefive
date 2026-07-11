`include "common.svh"

module shim (
    input  logic                    clk,
    input  logic                    rst,

    input  takefive_pkg::mem_req_t  dmem_mmio_req,
    output takefive_pkg::mem_rsp_t  dmem_mmio_rsp,
    output logic                    dmem_mmio_rdy,

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
    `m_axi_intf                    (imem),
    `m_axi_intf                    (dmem)
    );

    // ---- MMIO decode ----

    logic [5:0] word   ;
    logic       mmio_wr;
    logic       mmio_rd;
    assign word    = dmem_mmio_req.addr[7:2];
    assign mmio_wr = dmem_mmio_req.vld &&  dmem_mmio_req.wen;
    assign mmio_rd = dmem_mmio_req.vld && !dmem_mmio_req.wen;

    // ---- dbg_pause ----

    logic dbg_stop_core;

    always_ff @(posedge clk) begin
        if (rst) dbg_stop_core <= 1'b0;
        else if (mmio_wr && word == takefive_pkg::MMIO_ADDR_EXIT[7:2]) dbg_stop_core <= 1'b1;
    end

    assign dbg_pause = dbg_stop_core | dbg_prog;

    // ---- AXI Stream master ----

    assign m_axis_tvalid = mmio_wr && word == takefive_pkg::MMIO_ADDR_STREAM[7:2];
    assign m_axis_tdata  = dmem_mmio_req.data;

    // ---- AXI Stream slave ----

    assign s_axis_tready = mmio_rd && word == takefive_pkg::MMIO_ADDR_STREAM[7:2];

    // ---- MMIO distributed RAM ----

    logic  [4:0] saxil_raddr;
    logic [31:0] saxil_rdata;

    logic mmio_ram_we;
    assign mmio_ram_we = mmio_wr && word < takefive_pkg::MMIO_DATA_WORDS[7:2];

    ram #(.WIDTH(32), .DEPTH(32)) u_mmio_ram(
        .clk  (clk                    ),
        .we   (mmio_ram_we            ),
        .a    (dmem_mmio_req.addr[6:2]),
        .di   (dmem_mmio_req.data     ),
        .dpra (saxil_raddr            ),
        .dpo  (saxil_rdata            )
    );

    // ---- AXI-Lite slave ----

    logic [31:0] imem_base ;
    logic [31:0] imem_bound;
    logic [31:0] dmem_base ;
    logic [31:0] dmem_bound;

    saxil u_saxil(
        .clk           (clk        ),
        .rst           (rst        ),
        `axil_bind     (mmio, mmio ),
        .mmio_raddr    (saxil_raddr),
        .mmio_rdata    (saxil_rdata),
        .imem_base     (imem_base  ),
        .imem_bound    (imem_bound ),
        .dmem_base     (dmem_base  ),
        .dmem_bound    (dmem_bound )
    );

    // ---- maxil instances ----

    maxil u_imem_maxil(
        .clk      (clk          ),
        .rst      (rst          ),
        .base     (imem_base    ),
        .bound    (imem_bound   ),
        .dram_req (imem_dram_req),
        .dram_rsp (imem_dram_rsp),
        .dram_rdy (imem_dram_rdy),
        `axi_bind (axi, imem)
    );

    maxil u_dmem_maxil(
        .clk      (clk          ),
        .rst      (rst          ),
        .base     (dmem_base    ),
        .bound    (dmem_bound   ),
        .dram_req (dmem_dram_req),
        .dram_rsp (dmem_dram_rsp),
        .dram_rdy (dmem_dram_rdy),
        `axi_bind (axi, dmem)
    );

    // ---- MMIO response ----

    assign dmem_mmio_rdy = 1'b1;

    logic [31:0] mmio_rd_data;
    always_comb begin
        if (word == takefive_pkg::MMIO_ADDR_STREAM[7:2])      mmio_rd_data = s_axis_tdata;
        else if (word == takefive_pkg::MMIO_ADDR_RLEVEL[7:2]) mmio_rd_data = s_axis_level;
        else                                                  mmio_rd_data = 32'h0;
    end

    always_ff @(posedge clk) begin
        if (rst) dmem_mmio_rsp <= '0;
        else begin
            dmem_mmio_rsp.vld  <= dmem_mmio_req.vld;
            dmem_mmio_rsp.uid  <= dmem_mmio_req.uid;
            dmem_mmio_rsp.data <= mmio_rd_data;
        end
    end

endmodule
