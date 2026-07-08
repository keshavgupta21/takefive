`include "common.svh"

module mmu (
    input  takefive_pkg::mem_req_t  imem_pipe_req,
    output takefive_pkg::mem_rsp_t  imem_pipe_rsp,
    output logic                    imem_pipe_rdy,

    output takefive_pkg::mem_req_t  imem_cache_req,
    input  takefive_pkg::mem_rsp_t  imem_cache_rsp,
    input  logic                    imem_cache_rdy,

    input  takefive_pkg::mem_req_t  dmem_pipe_req,
    output takefive_pkg::mem_rsp_t  dmem_pipe_rsp,
    output logic                    dmem_pipe_rdy,

    output takefive_pkg::mem_req_t  dmem_cache_req,
    input  takefive_pkg::mem_rsp_t  dmem_cache_rsp,
    input  logic                    dmem_cache_rdy,

    output takefive_pkg::mem_req_t  mmio_req,
    input  takefive_pkg::mem_rsp_t  mmio_rsp,
    input  logic                    mmio_rdy
);

    // Instruction path: pass address through unchanged
    assign imem_cache_req = imem_pipe_req;
    assign imem_pipe_rsp  = imem_cache_rsp;
    assign imem_pipe_rdy  = imem_cache_rdy;

    // Data path: 0xFF000000–0xFFFFFFFF → MMIO, everything else → dcache
    logic is_mmio;
    assign is_mmio = (dmem_pipe_req.addr[31:8] == 24'hFFFFFF);

    always_comb begin
        dmem_cache_req     = dmem_pipe_req;
        dmem_cache_req.vld = dmem_pipe_req.vld && !is_mmio;
    end

    always_comb begin
        mmio_req     = dmem_pipe_req;
        mmio_req.vld = dmem_pipe_req.vld && is_mmio;
    end

    assign dmem_pipe_rdy = mmio_rdy && dmem_cache_rdy;

    always_comb begin
        if (mmio_rsp.vld) dmem_pipe_rsp = mmio_rsp;
        else              dmem_pipe_rsp = dmem_cache_rsp;
    end

endmodule
