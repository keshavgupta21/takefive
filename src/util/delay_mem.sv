`include "common.svh"

module delay_mem #(
    parameter DEPTH = 1024
)(
    input  logic                   clk,
    input  logic                   rst,
    input  logic                   dbg,
    input  takefive_pkg::mem_req_t req,
    output takefive_pkg::mem_rsp_t rsp,
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

    wire [AWIDTH-1:0] idx     = req.addr[AWIDTH+1:2];
    wire [AWIDTH-1:0] ram_idx = (busy && !dbg) ? lat_idx : idx;
    wire              accept  = req.vld && (!busy || dbg);

    always_ff @(posedge clk) begin
        if (accept && req.wen) ram[ram_idx] <= req.data;
        dout <= ram[ram_idx];
    end

    always_ff @(posedge clk) begin
        if (rst || dbg) begin
            req_cnt  <= '0;
            dly_cnt  <= '0;
            busy     <= 0;
            rsp.vld  <= 0;
            rsp.addr <= req.addr;
            lat_idx  <= '0;
            lat_addr <= '0;
        end else if (busy) begin
            if (dly_cnt == 5'd1) begin
                rsp.vld  <= 1;
                rsp.addr <= lat_addr;
                busy     <= 0;
            end else begin
                rsp.vld <= 0;
                dly_cnt <= dly_cnt - 1;
            end
        end else if (accept) begin
            if (req_cnt == 4'd9) begin
                busy     <= 1;
                dly_cnt  <= 5'd19;
                lat_idx  <= idx;
                lat_addr <= req.addr;
                req_cnt  <= '0;
                rsp.vld  <= 0;
            end else begin
                rsp.vld  <= 1;
                rsp.addr <= req.addr;
                req_cnt  <= req_cnt + 1;
            end
        end else begin
            rsp.vld <= 0;
        end
    end

    assign rsp.data = dout;
    assign mem_rdy  = !busy || dbg;

endmodule
