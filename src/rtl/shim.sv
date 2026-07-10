`include "common.svh"

module shim (
    input  logic clk,
    input  logic rst,

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

    input  logic [7:0]              s_mmio_araddr,
    input  logic [2:0]              s_mmio_arprot,
    input  logic                    s_mmio_arvalid,
    output logic                    s_mmio_arready,

    output logic [31:0]             s_mmio_rdata,
    output logic [1:0]              s_mmio_rresp,
    output logic                    s_mmio_rvalid,
    input  logic                    s_mmio_rready,

    input  logic [7:0]              s_mmio_awaddr,
    input  logic [2:0]              s_mmio_awprot,
    input  logic                    s_mmio_awvalid,
    output logic                    s_mmio_awready,

    input  logic [31:0]             s_mmio_wdata,
    input  logic [3:0]              s_mmio_wstrb,
    input  logic                    s_mmio_wvalid,
    output logic                    s_mmio_wready,

    output logic [1:0]              s_mmio_bresp,
    output logic                    s_mmio_bvalid,
    input  logic                    s_mmio_bready,

    output logic                    m_axis_tvalid,
    input  logic                    m_axis_tready,
    output logic [31:0]             m_axis_tdata,

    input  logic                    s_axis_tvalid,
    output logic                    s_axis_tready,
    input  logic [31:0]             s_axis_tdata,
    input  logic [31:0]             s_axis_level
);

    // ---- imem passthrough ----

    assign imem_cache_req = imem_pipe_req;
    assign imem_pipe_rsp  = imem_cache_rsp;
    assign imem_pipe_rdy  = imem_cache_rdy;

    // ---- MMIO decode ----

    // Word index constants (addr[7:2], 0–63 over the 256-byte MMIO region)
    localparam DATA_WORDS  = 6'h20;  // data region: word < DATA_WORDS (0xFFFFFF00–7C)
    localparam RLEVEL_WORD = 6'h3D;  // 0xFFFFFFF4 — RX FIFO level
    localparam PUTC_WORD   = 6'h3E;  // 0xFFFFFFF8 — putc/getc
    localparam EXIT_WORD   = 6'h3F;  // 0xFFFFFFFC — exit

    logic        is_mmio;
    logic [5:0]  word;
    assign is_mmio = (dmem_pipe_req.addr[31:8] == 24'hFFFFFF);
    assign word    = dmem_pipe_req.addr[7:2];

    // ---- dbg_pause register ----

    always_ff @(posedge clk) begin
        if (rst)
            dbg_pause <= 1'b1;
        else if (dmem_pipe_req.vld && is_mmio && dmem_pipe_req.wen && word == EXIT_WORD)
            dbg_pause <= 1'b1;
        else
            dbg_pause <= 1'b0;
    end

    // ---- AXI Stream master (putc) ----

    assign m_axis_tvalid = dmem_pipe_req.vld && is_mmio && dmem_pipe_req.wen
                           && word == PUTC_WORD;
    assign m_axis_tdata  = dmem_pipe_req.data;

    // ---- AXI Stream slave (getc) ----

    assign s_axis_tready = dmem_pipe_req.vld && is_mmio && !dmem_pipe_req.wen
                           && word == PUTC_WORD;

    // ---- AXI read state machine ----

    localparam S_IDLE  = 2'b00,
               S_RADDR = 2'b10,
               S_RDATA = 2'b11;

    logic [7:0] axi_araddr;
    logic       axi_arready;
    logic       axi_rvalid;
    logic [1:0] state_read;

    // ---- MMIO distributed RAM ----

    logic        ar_handshake;
    logic [4:0]  dpra_sel;
    logic [31:0] mmio_rdata;
    logic [31:0] rdata_reg;

    assign ar_handshake = s_mmio_arvalid && axi_arready && (state_read == S_RADDR);
    assign dpra_sel     = ar_handshake ? s_mmio_araddr[6:2] : axi_araddr[6:2];

    ram #(.WIDTH(32), .DEPTH(32)) u_mmio_ram(
        .clk  (clk                                                              ),
        .we   (dmem_pipe_req.vld && is_mmio && dmem_pipe_req.wen && word < DATA_WORDS),
        .a    (dmem_pipe_req.addr[6:2]                                          ),
        .di   (dmem_pipe_req.data                                               ),
        .dpra (dpra_sel                                                         ),
        .dpo  (mmio_rdata                                                       )
    );

    always_ff @(posedge clk) begin
        if (ar_handshake) begin
            if (s_mmio_araddr[7:2] < DATA_WORDS) rdata_reg <= mmio_rdata;
            else                                  rdata_reg <= 32'h0;
        end
    end

    // ---- AXI read state machine (continued) ----

    assign s_mmio_arready = axi_arready;
    assign s_mmio_rvalid  = axi_rvalid;
    assign s_mmio_rresp   = 2'b00;
    assign s_mmio_rdata   = rdata_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            axi_arready <= 1'b0;
            axi_rvalid  <= 1'b0;
            axi_araddr  <= '0;
            state_read  <= S_IDLE;
        end else case (state_read)
            S_IDLE: begin
                state_read  <= S_RADDR;
                axi_arready <= 1'b1;
            end
            S_RADDR:
                if (s_mmio_arvalid && axi_arready) begin
                    axi_araddr  <= s_mmio_araddr;
                    axi_arready <= 1'b0;
                    axi_rvalid  <= 1'b1;
                    state_read  <= S_RDATA;
                end
            S_RDATA:
                if (axi_rvalid && s_mmio_rready) begin
                    axi_rvalid  <= 1'b0;
                    axi_arready <= 1'b1;
                    state_read  <= S_RADDR;
                end
            default: state_read <= S_IDLE;
        endcase
    end

    // ---- AXI write channel (tied off) ----

    assign s_mmio_awready = 1'b0;
    assign s_mmio_wready  = 1'b0;
    assign s_mmio_bvalid  = 1'b0;
    assign s_mmio_bresp   = 2'b00;

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
