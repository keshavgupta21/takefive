`include "common.svh"

module icache(
    input  logic                    clk,
    input  logic                    rst,

    input  takefive_pkg::mem_req_t  mem_req,
    output takefive_pkg::mem_rsp_t  mem_rsp,
    output logic                    mem_rdy,

    output takefive_pkg::dram_req_t dram_req,
    input  takefive_pkg::dram_rsp_t dram_rsp,
    input  logic                    dram_rdy
);

    localparam CACHE_DEPTH = takefive_pkg::CACHE_DEPTH;
    localparam CL_WORDS    = takefive_pkg::CL_WORDS;
    localparam IDX_BITS    = takefive_pkg::IDX_BITS;
    localparam CL_BITS     = takefive_pkg::CL_BITS;
    localparam TAG_BITS    = takefive_pkg::TAG_BITS;

    // = $bits(takefive_pkg::cacheline_t); manual expansion required for Yosys
    localparam CL_WIDTH    = 1 + TAG_BITS + CL_WORDS * 32;

    typedef enum logic [1:0] { REQ, FETCH, FILL } state_t;

    state_t              state;
    takefive_pkg::addr_t lat_addr;
    logic [31:0]         lat_uid;

    takefive_pkg::addr_t addr;
    assign addr.tag = mem_req.addr[31:IDX_BITS+CL_BITS+2];
    assign addr.idx = mem_req.addr[IDX_BITS+CL_BITS+1:CL_BITS+2];
    assign addr.wo  = mem_req.addr[CL_BITS+1:2];
    assign addr.bo  = mem_req.addr[1:0];

    // ---------------- Cache Memory ----------------

    logic [CACHE_DEPTH-1:0] cache_mem_vld;
    logic                   cache_mem_we;
    logic [IDX_BITS-1:0]    cache_mem_wa;
    logic [CL_WIDTH-1:0]    cache_mem_wd;
    logic [CL_WIDTH-1:0]    cache_mem_rd;

    takefive_pkg::cacheline_t fill_line;
    assign fill_line.dirty = 1'b0;
    assign fill_line.tag   = lat_addr.tag;
    assign fill_line.words = dram_rsp.data;
    assign cache_mem_wd    = fill_line;

    ram #(.WIDTH(CL_WIDTH), .DEPTH(CACHE_DEPTH)) u_cache_mem(
        .clk  (clk          ),
        .we   (cache_mem_we ),
        .a    (cache_mem_wa ),
        .dpra (addr.idx     ),
        .di   (cache_mem_wd ),
        .dpo  (cache_mem_rd )
    );

    takefive_pkg::cacheline_t line;
    assign line = cache_mem_rd;

    logic cache_hit;
    assign cache_hit = cache_mem_vld[addr.idx] && (line.tag == addr.tag);

    assign cache_mem_we = (state == FILL) && dram_rsp.vld;
    assign cache_mem_wa = lat_addr.idx;

    // ---------------- DRAM Request ----------------

    always_ff @(posedge clk) begin
        dram_req.vld  <= (state == FETCH) && dram_rdy;
        dram_req.addr <= {lat_addr.tag, lat_addr.idx, {CL_BITS{1'b0}}, 2'b00};
        dram_req.wen  <= 1'b0;
        dram_req.data <= '0;
    end

    // ---------------- Cache Response ----------------

    logic rsp_hit, rsp_fill;
    assign rsp_hit  = (state == REQ) && mem_req.vld && cache_hit;
    assign rsp_fill = (state == FILL) && dram_rsp.vld;

    always_ff @(posedge clk) begin
        mem_rsp.vld  <= rsp_hit || rsp_fill;
        mem_rsp.data <= rsp_fill ? dram_rsp.data[lat_addr.wo] : line.words[addr.wo];
        mem_rsp.uid  <= rsp_fill ? lat_uid : mem_req.uid;
    end

    // ---------------- State Machine ----------------

    always_ff @(posedge clk) begin
        if (rst) begin
            state         <= REQ;
            mem_rdy       <= 1;
            cache_mem_vld <= '0;
            lat_addr      <= '0;
            lat_uid       <= '0;
        end else if (state == REQ && mem_req.vld && !cache_hit) begin
            lat_addr <= addr;
            lat_uid  <= mem_req.uid;
            mem_rdy  <= 0;
            state    <= FETCH;
        end else if (state == FETCH && dram_rdy) begin
            state <= FILL;
        end else if (state == FILL && dram_rsp.vld) begin
            cache_mem_vld[lat_addr.idx] <= 1;
            mem_rdy                     <= 1;
            state                       <= REQ;
        end
    end

endmodule
