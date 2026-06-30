`include "common.svh"

module dram_mem (
    input  logic                                     clk,
    input  logic                                     rst,

    input  logic                                     dbg_pause,
    input  takefive_pkg::mem_req_t                   dbg_req,

    input  takefive_pkg::dram_req_t                  dram_req,

    output takefive_pkg::dram_rsp_t                  dram_rsp,
    output logic                                     dram_rdy
);

    localparam DEPTH    = takefive_pkg::DRAM_WORDS;
    localparam CL_WORDS = takefive_pkg::CL_WORDS;
    localparam LINES    = DEPTH / CL_WORDS;
    localparam AWIDTH   = $clog2(LINES);
    localparam LWIDTH   = $clog2(CL_WORDS);

    logic [CL_WORDS-1:0][31:0] ram [0:LINES-1];

    logic [4:0]                 dly_cnt;
    logic                       busy;
    logic                       lat_wen;
    logic [AWIDTH-1:0]          lat_idx;
    logic [CL_WORDS-1:0][31:0]  lat_data;

    logic [AWIDTH-1:0] idx;
    logic [AWIDTH-1:0] dbg_line;
    logic [LWIDTH-1:0] dbg_word;
    logic              accept;
    assign idx      = dram_req.addr[LWIDTH+AWIDTH+1:LWIDTH+2];
    assign dbg_line = dbg_req.addr[LWIDTH+AWIDTH+1:LWIDTH+2];
    assign dbg_word = dbg_req.addr[LWIDTH+1:2];
    assign accept   = dram_req.vld && !busy;

    always_ff @(posedge clk) begin
        if (busy && lat_wen && dly_cnt == 5'd1) ram[lat_idx]            <= lat_data;
        if (busy && !lat_wen)                   dram_rsp.data                <= ram[lat_idx];
        if (dbg_req.vld && dbg_req.wen)         ram[dbg_line][dbg_word] <= dbg_req.data;
    end

    always_ff @(posedge clk) begin
        if (rst || dbg_pause) begin
            dly_cnt  <= '0;
            busy     <= 0;
            dram_rsp.vld  <= 0;
            lat_wen  <= 0;
            lat_idx  <= '0;
        end else if (busy) begin
            if (dly_cnt == 5'd1) begin
                dram_rsp.vld <= !lat_wen;
                busy         <= 0;
            end else begin
                dram_rsp.vld <= 0;
                dly_cnt <= dly_cnt - 1;
            end
        end else if (accept) begin
            busy     <= 1;
            dly_cnt  <= 5'd20;
            lat_idx  <= idx;
            lat_wen  <= dram_req.wen;
            lat_data <= dram_req.data;
            dram_rsp.vld  <= 0;
        end else begin
            dram_rsp.vld  <= 0;
        end
    end

    assign dram_rdy = !busy;

endmodule
