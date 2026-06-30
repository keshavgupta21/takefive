`include "common.svh"

module delay_mem (
    input  logic                   clk,
    input  logic                   rst,

    input  logic                   dbg_pause,
    input  takefive_pkg::mem_req_t dbg_req,

    input  takefive_pkg::mem_req_t mem_req,
    output takefive_pkg::mem_rsp_t mem_rsp,
    output logic                   mem_rdy
);

    localparam DEPTH  = takefive_pkg::DRAM_WORDS;
    localparam AWIDTH = $clog2(DEPTH);

    (* ram_style = "block" *) logic [31:0] ram [0:DEPTH-1];
    logic [31:0] dout;

    logic [3:0]        req_cnt;
    logic [4:0]        dly_cnt;
    logic              busy;
    logic              lat_oob;
    logic [AWIDTH-1:0] lat_idx;
    logic [31:0]       lat_uid;

    logic [AWIDTH-1:0] idx;
    logic [AWIDTH-1:0] dbg_idx;
    logic [AWIDTH-1:0] ram_idx;
    logic              oob;
    logic              accept;
    assign idx     = mem_req.addr[AWIDTH+1:2];
    assign dbg_idx = dbg_req.addr[AWIDTH+1:2];
    assign ram_idx = busy ? lat_idx : idx;
    assign oob     = mem_req.vld && (mem_req.addr[31:AWIDTH+2] != '0);
    assign accept  = mem_req.vld && !busy;

    always_ff @(posedge clk) begin
        if (accept && mem_req.wen && !oob) ram[ram_idx] <= mem_req.data;
        if (dbg_req.vld && dbg_req.wen)    ram[dbg_idx] <= dbg_req.data;
        dout <= ram[ram_idx];
    end

    always_ff @(posedge clk) begin
        if (rst || dbg_pause) begin
            req_cnt     <= '0;
            dly_cnt     <= '0;
            busy        <= 0;
            lat_oob     <= 0;
            mem_rsp.vld <= 0;
            mem_rsp.uid <= mem_req.uid;
            lat_idx     <= '0;
            lat_uid     <= '0;
        end else if (busy) begin
            if (dly_cnt == 5'd1) begin
                mem_rsp.vld <= 1;
                mem_rsp.uid <= lat_uid;
                busy        <= 0;
            end else begin
                mem_rsp.vld <= 0;
                dly_cnt     <= dly_cnt - 1;
            end
        end else if (accept) begin
            if (oob) $warning("delay_mem: OOB address 0x%08x", mem_req.addr);
            lat_oob <= oob;
            if (req_cnt == 4'd9) begin
                busy        <= 1;
                dly_cnt     <= 5'd19;
                lat_idx     <= idx;
                lat_uid     <= mem_req.uid;
                req_cnt     <= '0;
                mem_rsp.vld <= 0;
            end else begin
                mem_rsp.vld <= 1;
                mem_rsp.uid <= mem_req.uid;
                req_cnt     <= req_cnt + 1;
            end
        end else begin
            mem_rsp.vld <= 0;
        end
    end

    assign mem_rsp.data = lat_oob ? '0 : dout;
    assign mem_rdy      = !busy;

endmodule
