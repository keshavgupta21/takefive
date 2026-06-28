`include "common.svh"

module delay_mem #(
    parameter DEPTH = 1024
)(
    input  logic                   clk,
    input  logic                   rst,

    input  logic                   dbg_pause,
    input  takefive_pkg::mem_req_t dbg_req,

    input  takefive_pkg::mem_req_t mem_req,
    output takefive_pkg::mem_rsp_t mem_rsp,
    output logic                   mem_rdy
);

    localparam AWIDTH = $clog2(DEPTH);

    (* ram_style = "block" *) logic [31:0] ram [0:DEPTH-1];
    logic [31:0] dout;

    logic [3:0]        req_cnt;
    logic [4:0]        dly_cnt;
    logic              busy;
    logic [AWIDTH-1:0] lat_idx;
    logic [31:0]       lat_addr;

    wire [AWIDTH-1:0] idx     = mem_req.addr[AWIDTH+1:2];
    wire [AWIDTH-1:0] dbg_idx = dbg_req.addr[AWIDTH+1:2];
    wire [AWIDTH-1:0] ram_idx = busy ? lat_idx : idx;
    wire              accept  = mem_req.vld && !busy;

    always_ff @(posedge clk) begin
        if (accept && mem_req.wen)       ram[ram_idx] <= mem_req.data;
        if (dbg_req.vld && dbg_req.wen)  ram[dbg_idx] <= dbg_req.data;
        dout <= ram[ram_idx];
    end

    always_ff @(posedge clk) begin
        if (rst || dbg_pause) begin
            req_cnt      <= '0;
            dly_cnt      <= '0;
            busy         <= 0;
            mem_rsp.vld  <= 0;
            mem_rsp.addr <= mem_req.addr;
            lat_idx      <= '0;
            lat_addr     <= '0;
        end else if (busy) begin
            if (dly_cnt == 5'd1) begin
                mem_rsp.vld  <= 1;
                mem_rsp.addr <= lat_addr;
                busy         <= 0;
            end else begin
                mem_rsp.vld  <= 0;
                dly_cnt      <= dly_cnt - 1;
            end
        end else if (accept) begin
            if (req_cnt == 4'd9) begin
                busy         <= 1;
                dly_cnt      <= 5'd19;
                lat_idx      <= idx;
                lat_addr     <= mem_req.addr;
                req_cnt      <= '0;
                mem_rsp.vld  <= 0;
            end else begin
                mem_rsp.vld  <= 1;
                mem_rsp.addr <= mem_req.addr;
                req_cnt      <= req_cnt + 1;
            end
        end else begin
            mem_rsp.vld <= 0;
        end
    end

    assign mem_rsp.data = dout;
    assign mem_rdy      = !busy;

endmodule
