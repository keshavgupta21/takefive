`include "common.svh"

module dcache(
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

    typedef enum logic [2:0] { REQ, EVICT, WAIT, FETCH, FILL } state_t;

    state_t              state;
    takefive_pkg::addr_t lat_addr;
    logic [31:0]         lat_data;
    logic [31:0]         lat_uid;
    logic                lat_wen;

    takefive_pkg::cacheline_t evict_line;
    logic                     evict_way;

    takefive_pkg::addr_t addr;
    assign addr.tag = mem_req.addr[31:IDX_BITS+CL_BITS+2];
    assign addr.idx = mem_req.addr[IDX_BITS+CL_BITS+1:CL_BITS+2];
    assign addr.wo  = mem_req.addr[CL_BITS+1:2];
    assign addr.bo  = mem_req.addr[1:0];

    // ---------------- Cache Memory ----------------

    logic [CACHE_DEPTH-1:0]      lru_way;
    logic [1:0][CACHE_DEPTH-1:0] cache_mem_vld;
    logic [1:0]                  cache_mem_we;
    logic [1:0][IDX_BITS-1:0]    cache_mem_wa;
    logic [1:0][CL_WIDTH-1:0]    cache_mem_wd;
    logic [1:0][CL_WIDTH-1:0]    cache_mem_rd;

    takefive_pkg::cacheline_t fill_line;
    always_comb begin
        fill_line.dirty                           = lat_wen;
        fill_line.tag                             = lat_addr.tag;
        fill_line.words                           = dram_rsp.data;
        if (lat_wen) fill_line.words[lat_addr.wo] = lat_data;
    end

    logic [1:0] cache_hit;

    logic hit_way;
    assign hit_way = cache_hit[1];

    generate for(genvar i = 0; i < 2; i++) begin: gen_cache_mem
        

        ram #(.WIDTH(CL_WIDTH), .DEPTH(CACHE_DEPTH)) u_cache_mem(
            .clk  (clk             ),
            .we   (cache_mem_we[i] ),
            .a    (cache_mem_wa[i] ),
            .dpra (addr.idx        ),
            .di   (cache_mem_wd[i] ),
            .dpo  (cache_mem_rd[i] )
        );

        takefive_pkg::cacheline_t cache_rd_line, cache_wr_line;
        assign cache_rd_line = cache_mem_rd[i];
        assign cache_hit[i]  = cache_mem_vld[i][addr.idx] && (cache_rd_line.tag == addr.tag);

        always_comb begin
            cache_wr_line                = cache_mem_rd[i];
            cache_wr_line.words[addr.wo] = mem_req.data;
            cache_wr_line.dirty          = 1'b1;

            if ((state == REQ) && mem_req.vld && |cache_hit && mem_req.wen) begin
                cache_mem_we[i] = (hit_way == i[0]);
                cache_mem_wa[i] = addr.idx;
                cache_mem_wd[i] = cache_wr_line;
            end else if ((state == FILL) && dram_rsp.vld) begin
                cache_mem_we[i] = (evict_way == i[0]);
                cache_mem_wa[i] = lat_addr.idx;
                cache_mem_wd[i] = fill_line;
            end else begin
                cache_mem_we[i] = 0;
                cache_mem_wa[i] = '0;
                cache_mem_wd[i] = '0;
            end
        end
    end endgenerate

    // ---------------- DRAM Request ----------------

    always_ff @(posedge clk) begin
        dram_req <= '0;
        if ((state == EVICT) && dram_rdy) begin
            dram_req.vld  <= 1;
            dram_req.addr <= {evict_line.tag, lat_addr.idx, {CL_BITS{1'b0}}, 2'b00};
            dram_req.wen  <= 1'b1;
            dram_req.data <= evict_line.words;
        end else if ((state == FETCH) && dram_rdy) begin
            dram_req.vld  <= 1;
            dram_req.addr <= {lat_addr.tag, lat_addr.idx, {CL_BITS{1'b0}}, 2'b00};
            dram_req.wen  <= 1'b0;
            dram_req.data <= '0;
        end
    end

    // ---------------- Cache Response ----------------

    logic rsp_hit, rsp_fill;
    assign rsp_hit  = (state == REQ) && mem_req.vld && |cache_hit;
    assign rsp_fill = (state == FILL) && dram_rsp.vld;

    takefive_pkg::cacheline_t cache_hit_line;
    assign cache_hit_line = cache_mem_rd[hit_way];

    always_ff @(posedge clk) begin
        mem_rsp.vld  <= rsp_hit || rsp_fill;
        mem_rsp.data <= rsp_fill ? dram_rsp.data[lat_addr.wo] : cache_hit_line.words[addr.wo];
        mem_rsp.uid  <= rsp_fill ? lat_uid : mem_req.uid;
    end

    // ---------------- State Machine ----------------
    takefive_pkg::cacheline_t cache_lru_line;
    assign cache_lru_line = cache_mem_rd[lru_way[addr.idx]];

    logic line_needs_wb;
    assign line_needs_wb = cache_mem_vld[lru_way[addr.idx]][addr.idx] && cache_lru_line.dirty;

    always_ff @(posedge clk) begin
        if (rst) begin
            state         <= REQ;
            mem_rdy       <= 1;
            cache_mem_vld <= '0;
            lat_addr      <= '0;
            lat_data      <= '0;
            lat_uid       <= '0;
            lat_wen       <= 0;
            evict_way     <= 0;
            lru_way       <= '0;
        end else if (state == REQ && mem_req.vld && |cache_hit) begin
            lru_way[addr.idx] <= ~hit_way;
        end else if (state == REQ && mem_req.vld && ~|cache_hit) begin
            lat_addr   <= addr;
            lat_data   <= mem_req.data;
            lat_uid    <= mem_req.uid;
            lat_wen    <= mem_req.wen;
            mem_rdy    <= 0;
            state      <= line_needs_wb ? EVICT : FETCH;
            evict_line <= cache_lru_line;
            evict_way  <= lru_way[addr.idx];
        end else if (state == EVICT && dram_rdy) state <= WAIT;
        else if (state == WAIT && dram_rdy)      state <= FETCH;
        else if (state == FETCH && dram_rdy)     state <= FILL;
        else if (state == FILL && dram_rsp.vld) begin
            cache_mem_vld[evict_way][lat_addr.idx] <= 1;
            mem_rdy                                <= 1;
            state                                  <= REQ;
            lru_way[lat_addr.idx]                  <= ~evict_way;
        end
    end

endmodule
