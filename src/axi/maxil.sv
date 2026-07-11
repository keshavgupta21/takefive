`include "common.svh"

module maxil (
    input  logic                     clk,
    input  logic                     rst,

    input  logic [31:0]              base,
    input  logic [31:0]              bound,

    input  takefive_pkg::dram_req_t  dram_req,
    output takefive_pkg::dram_rsp_t  dram_rsp,
    output logic                     dram_rdy,

    `m_axi_intf                      (axi)
);

    localparam CL = takefive_pkg::CL_WORDS;

    localparam [2:0] IDLE    = 3'b000,
                     RD      = 3'b001,
                     RD_DONE = 3'b010,
                     WR      = 3'b011,
                     OOB     = 3'b100;

    logic [2:0] state;

    // Per-channel beat counters; value == CL signals channel done
    logic [4:0] ar_count, r_count;
    logic [4:0] aw_count, w_count, b_count;

    logic [31:0]         req_addr;
    logic                req_wen;
    logic [CL-1:0][31:0] req_data;
    logic [CL-1:0][31:0] rsp_buf;

    // ---- read channel outputs ----

    assign m_axi_araddr  = base + req_addr + {25'b0, ar_count, 2'b00};
    assign m_axi_arprot  = 3'b000;
    assign m_axi_arvalid = (state == RD) && (ar_count < CL);
    assign m_axi_rready  = (state == RD) && (r_count  < CL);

    // ---- write channel outputs ----

    assign m_axi_awaddr  = base + req_addr + {25'b0, aw_count, 2'b00};
    assign m_axi_awprot  = 3'b000;
    assign m_axi_awvalid = (state == WR) && (aw_count < CL);
    assign m_axi_wdata   = req_data[w_count[3:0]];
    assign m_axi_wstrb   = 4'hF;
    assign m_axi_wvalid  = (state == WR) && (w_count  < CL);
    assign m_axi_bready  = (state == WR) && (b_count  < CL);

    // ---- DRAM outputs ----

    assign dram_rdy      = (state == IDLE);
    assign dram_rsp.vld  = (state == RD_DONE) || (state == OOB && !req_wen);
    assign dram_rsp.data = rsp_buf;

    // ---- state machine ----

    always_ff @(posedge clk) begin
        if (rst) begin
            state    <= IDLE;
            ar_count <= '0;
            r_count  <= '0;
            aw_count <= '0;
            w_count  <= '0;
            b_count  <= '0;
            req_addr <= '0;
            req_wen  <= '0;
            req_data <= '0;
            rsp_buf  <= '0;
        end else case (state)
            IDLE:
                if (dram_req.vld) begin
                    req_addr <= dram_req.addr;
                    req_wen  <= dram_req.wen;
                    req_data <= dram_req.data;
                    ar_count <= '0;
                    r_count  <= '0;
                    aw_count <= '0;
                    w_count  <= '0;
                    b_count  <= '0;
                    if (dram_req.addr >= bound) begin
                        rsp_buf <= '0;
                        state   <= OOB;
                    end else if (!dram_req.wen) state <= RD;
                    else                         state <= WR;
                end

            RD: begin
                if (m_axi_arready && ar_count < CL) ar_count <= ar_count + 1;
                if (m_axi_rvalid  && r_count  < CL) begin
                    rsp_buf[r_count[3:0]] <= m_axi_rdata;
                    r_count               <= r_count + 1;
                    if (r_count == CL - 1) state <= RD_DONE;
                end
            end

            RD_DONE: state <= IDLE;

            WR: begin
                if (m_axi_awready && aw_count < CL) aw_count <= aw_count + 1;
                if (m_axi_wready  && w_count  < CL) w_count  <= w_count  + 1;
                if (m_axi_bvalid  && b_count  < CL) begin
                    b_count <= b_count + 1;
                    if (b_count == CL - 1) state <= IDLE;
                end
            end

            OOB:     state <= IDLE;
            default: state <= IDLE;
        endcase
    end

endmodule
