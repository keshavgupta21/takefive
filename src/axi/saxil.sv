`include "common.svh"

module saxil (
    input  logic        clk,
    input  logic        rst,

    `s_axil_intf        (mmio),

    output logic [4:0]  mmio_raddr,
    input  logic [31:0] mmio_rdata,

    output logic [31:0] imem_base,
    output logic [31:0] imem_bound,
    output logic [31:0] dmem_base,
    output logic [31:0] dmem_bound
);

    // ---- AXI read state machine ----

    localparam S_IDLE  = 2'b00,
               S_RADDR = 2'b10,
               S_RDATA = 2'b11;

    logic [7:0] axi_araddr;
    logic       axi_arready;
    logic       axi_rvalid;
    logic [1:0] state_read;

    logic ar_handshake;
    assign ar_handshake = s_mmio_arvalid && axi_arready && (state_read == S_RADDR);
    assign mmio_raddr   = ar_handshake ? s_mmio_araddr[6:2] : axi_araddr[6:2];

    logic [31:0] rdata_reg;

    always_ff @(posedge clk) begin
        if (ar_handshake) begin
            if (s_mmio_araddr[7:2] < takefive_pkg::MMIO_DATA_WORDS[7:2]) rdata_reg <= mmio_rdata;
            else                        rdata_reg <= '0;
        end
    end

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

    // ---- AXI write state machine ----

    localparam S_WADDR = 2'b10,
               S_WDATA = 2'b11;

    logic [7:0] axi_awaddr;
    logic       axi_awready;
    logic       axi_wready;
    logic       axi_bvalid;
    logic [1:0] state_write;

    assign s_mmio_awready = axi_awready;
    assign s_mmio_wready  = axi_wready;
    assign s_mmio_bvalid  = axi_bvalid;
    assign s_mmio_bresp   = 2'b00;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_write <= S_IDLE;
            axi_awready <= 1'b0;
            axi_wready  <= 1'b0;
            axi_bvalid  <= 1'b0;
            axi_awaddr  <= '0;
        end else case (state_write)
            S_IDLE: begin
                axi_awready <= 1'b1;
                axi_wready  <= 1'b1;
                state_write <= S_WADDR;
            end
            S_WADDR: begin
                if (axi_bvalid && s_mmio_bready) axi_bvalid <= 1'b0;
                if (s_mmio_awvalid && axi_awready) begin
                    axi_awaddr <= s_mmio_awaddr;
                    if (s_mmio_wvalid) axi_bvalid <= 1'b1;
                    else begin
                        axi_awready <= 1'b0;
                        state_write <= S_WDATA;
                    end
                end
            end
            S_WDATA:
                if (s_mmio_wvalid) begin
                    axi_bvalid  <= 1'b1;
                    axi_awready <= 1'b1;
                    state_write <= S_WADDR;
                end
            default: state_write <= S_IDLE;
        endcase
    end

    // ---- MMIO write registers ----

    logic [7:0] wr_addr;
    assign wr_addr = (s_mmio_awvalid && axi_awready) ? s_mmio_awaddr : axi_awaddr;

    always_ff @(posedge clk) begin
        if (rst) begin
            imem_base  <= '0;
            imem_bound <= '0;
            dmem_base  <= '0;
            dmem_bound <= '0;
        end else if (s_mmio_wvalid && axi_wready) begin
            case (wr_addr)
                takefive_pkg::CFG_IMEM_BASE : imem_base  <= s_mmio_wdata;
                takefive_pkg::CFG_IMEM_BOUND: imem_bound <= s_mmio_wdata;
                takefive_pkg::CFG_DMEM_BASE : dmem_base  <= s_mmio_wdata;
                takefive_pkg::CFG_DMEM_BOUND: dmem_bound <= s_mmio_wdata;
                default:;
            endcase
        end
    end

endmodule
