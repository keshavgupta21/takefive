`include "common.svh"

module core (
    input  logic                       clk,
    input  logic                       rst,

    output takefive_pkg::dram_req_t    imem_dram_req,
    input  takefive_pkg::dram_rsp_t    imem_dram_rsp,
    input  logic                       imem_dram_rdy,

    output takefive_pkg::dram_req_t    dmem_dram_req,
    input  takefive_pkg::dram_rsp_t    dmem_dram_rsp,
    input  logic                       dmem_dram_rdy,

    output logic                       dbg_pause,
    output logic [31:0]                dbg_pc,
    output logic                       dbg_commit,
    output logic                       dbg_pipe_busy,

    input  logic [7:0]                 s_mmio_araddr,
    input  logic [2:0]                 s_mmio_arprot,
    input  logic                       s_mmio_arvalid,
    output logic                       s_mmio_arready,

    output logic [31:0]                s_mmio_rdata,
    output logic [1:0]                 s_mmio_rresp,
    output logic                       s_mmio_rvalid,
    input  logic                       s_mmio_rready,

    input  logic [7:0]                 s_mmio_awaddr,
    input  logic [2:0]                 s_mmio_awprot,
    input  logic                       s_mmio_awvalid,
    output logic                       s_mmio_awready,

    input  logic [31:0]                s_mmio_wdata,
    input  logic [3:0]                 s_mmio_wstrb,
    input  logic                       s_mmio_wvalid,
    output logic                       s_mmio_wready,

    output logic [1:0]                 s_mmio_bresp,
    output logic                       s_mmio_bvalid,
    input  logic                       s_mmio_bready,

    output logic                       m_axis_tvalid,
    input  logic                       m_axis_tready,
    output logic [31:0]                m_axis_tdata,

    input  logic                       s_axis_tvalid,
    output logic                       s_axis_tready,
    input  logic [31:0]                s_axis_tdata,
    input  logic [31:0]                s_axis_level
);

    // ---------------- Shim + Caches ----------------

    takefive_pkg::mem_req_t imem_req, imem_cache_req;
    takefive_pkg::mem_rsp_t imem_rsp, imem_cache_rsp;
    logic                   imem_rdy, imem_cache_rdy;

    takefive_pkg::mem_req_t dmem_req, dmem_cache_req;
    takefive_pkg::mem_rsp_t dmem_rsp, dmem_cache_rsp;
    logic                   dmem_rdy, dmem_cache_rdy;

    logic dbg_pause_shim;
    assign dbg_pause = dbg_pause_shim;

    shim u_shim(
        .clk            (clk            ),
        .rst            (rst            ),
        .imem_pipe_req  (imem_req       ),
        .imem_pipe_rsp  (imem_rsp       ),
        .imem_pipe_rdy  (imem_rdy       ),
        .imem_cache_req (imem_cache_req ),
        .imem_cache_rsp (imem_cache_rsp ),
        .imem_cache_rdy (imem_cache_rdy ),
        .dmem_pipe_req  (dmem_req       ),
        .dmem_pipe_rsp  (dmem_rsp       ),
        .dmem_pipe_rdy  (dmem_rdy       ),
        .dmem_cache_req (dmem_cache_req ),
        .dmem_cache_rsp (dmem_cache_rsp ),
        .dmem_cache_rdy (dmem_cache_rdy ),
        .dbg_pause      (dbg_pause_shim ),
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

    icache u_icache(
        .clk      (clk            ),
        .rst      (rst            ),
        .mem_req  (imem_cache_req ),
        .mem_rsp  (imem_cache_rsp ),
        .mem_rdy  (imem_cache_rdy ),
        .dram_req (imem_dram_req  ),
        .dram_rsp (imem_dram_rsp  ),
        .dram_rdy (imem_dram_rdy  )
    );

    dcache u_dcache(
        .clk      (clk            ),
        .rst      (rst            ),
        .mem_req  (dmem_cache_req ),
        .mem_rsp  (dmem_cache_rsp ),
        .mem_rdy  (dmem_cache_rdy ),
        .dram_req (dmem_dram_req  ),
        .dram_rsp (dmem_dram_rsp  ),
        .dram_rdy (dmem_dram_rdy  )
    );

    //         --- PIPELINE STAGE 1 ---
    // ---------------- Fetch ----------------
    takefive_pkg::f2d_t    f2d;
    takefive_pkg::annul_t annul;

    logic dec_stall, rf_stall, dmem_stall, wb_stall, stall;
    assign stall = dec_stall || rf_stall || dmem_stall || wb_stall;

    fetch u_fetch(
        .clk       (clk            ),
        .rst       (rst            ),
        .mem_req   (imem_req       ),
        .mem_rsp   (imem_rsp       ),
        .mem_rdy   (imem_rdy       ),
        .f2d       (f2d            ),
        .annul     (annul          ),
        .stall     (stall          ),
        .dbg_pause (dbg_pause_shim )
    );

    //         --- PIPELINE STAGE 2 ---
    // ---------------- Decode ----------------
    takefive_pkg::d2r_t d2r;

    dec u_dec(
        .f2d (f2d),
        .d2r (d2r)
    );

    assign dec_stall = !f2d.vld;

    // ---------------- RegFile ----------------
    takefive_pkg::rf_rd_req_t rf_rd_req;
    takefive_pkg::rf_rd_rsp_t rf_rd_rsp;
    takefive_pkg::rf_wr_req_t rf_wr_req;

    rf u_rf(
        .clk       (clk       ),
        .rst       (rst       ),
        .rf_rd_req (rf_rd_req ),
        .rf_rd_rsp (rf_rd_rsp ),
        .rf_wr_req (rf_wr_req )
    );

    assign rf_rd_req.rs1 = d2r.inst.rs1;
    assign rf_rd_req.rs2 = d2r.inst.rs2;

    takefive_pkg::rf_rd_rsp_t byp_rvals;

    bypass u_bypass(
        .inst       (d2r.inst   ),
        .rd_rvals   (rf_rd_rsp  ),
        .r2e        (r2e        ),
        .rf_wr_req  (rf_wr_req  ),
        .byp_rvals  (byp_rvals  ),
        .stall      (rf_stall   )
    );

    takefive_pkg::r2e_t r2e;
    always_ff @(posedge clk) begin
        if (rst) begin
            r2e.vld   <= 0;
            r2e.pc    <= '0;
            r2e.inst  <= '0;
            r2e.rvals <= '0;
        end else if (!dmem_stall && !wb_stall) begin
            if (annul.annul || dec_stall || rf_stall) begin
                r2e.vld   <= 0;
                r2e.pc    <= '0;
                r2e.inst  <= '0;
                r2e.rvals <= '0;
            end else begin
                r2e.vld   <= d2r.vld;
                r2e.pc    <= d2r.pc;
                r2e.inst  <= d2r.inst;
                r2e.rvals <= byp_rvals;
            end
        end
    end

    //         --- PIPELINE STAGE 3 ---
    // ---------------- Execute / Mem ----------------
    branch u_branch(
        .r2e   (r2e  ),
        .annul (annul)
    );

    logic [31:0] alu_out;

    alu u_alu(
        .r2e     (r2e    ),
        .alu_out (alu_out)
    );

    mem u_mem(
        .r2e      (r2e       ),
        .dmem_rdy (dmem_rdy  ),
        .mem_req  (dmem_req  ),
        .stall    (dmem_stall)
    );

    takefive_pkg::e2w_t e2w;
    always_ff @(posedge clk) begin
        if (rst) begin
            e2w.vld     <= 0;
            e2w.pc      <= '0;
            e2w.inst    <= '0;
            e2w.rvals   <= '0;
            e2w.alu_out <= '0;
        end else if (!wb_stall) begin
            if (dmem_stall) begin
                e2w.vld     <= 0;
                e2w.pc      <= '0;
                e2w.inst    <= '0;
                e2w.rvals   <= '0;
                e2w.alu_out <= '0;
            end else begin
                e2w.vld     <= r2e.vld;
                e2w.pc      <= r2e.pc;
                e2w.inst    <= r2e.inst;
                e2w.rvals   <= r2e.rvals;
                e2w.alu_out <= alu_out;
            end
        end
    end

    //         --- PIPELINE STAGE 4 ---
    // ---------------- Writeback ----------------
    wb u_wb(
        .e2w        (e2w        ),
        .dmem_rsp   (dmem_rsp   ),
        .rf_wr_req  (rf_wr_req  ),
        .stall      (wb_stall   )
    );

    always_ff @(posedge clk) begin
        if (rst || wb_stall) begin
            dbg_pc     <= '0;
            dbg_commit <= 0;
        end else begin
            dbg_pc     <= e2w.pc;
            dbg_commit <= e2w.vld;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) dbg_pipe_busy <= 0;
        else     dbg_pipe_busy <= f2d.vld | r2e.vld | e2w.vld;
    end

endmodule
