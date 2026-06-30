`include "common.svh"

module mmu (
    input  takefive_pkg::mem_req_t pipe_req,
    output takefive_pkg::mem_rsp_t pipe_rsp,
    output logic                   pipe_rdy,
    
    output takefive_pkg::mem_req_t cache_req,
    input  takefive_pkg::mem_rsp_t cache_rsp,
    input  logic                   cache_rdy
);
    localparam ADDR_BITS = $clog2(takefive_pkg::DRAM_WORDS) + 2;

    always_comb begin
        cache_req      = pipe_req;
        cache_req.addr = {{(32-ADDR_BITS){1'b0}}, pipe_req.addr[ADDR_BITS-1:0]};
    end

    assign pipe_rsp = cache_rsp;
    assign pipe_rdy = cache_rdy;

endmodule
