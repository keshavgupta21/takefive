`include "common.svh"

module mem_wrap (
    input  logic        inst_vld,
    input  logic [6:0]  inst_opc,
    input  logic [4:0]  inst_rd,
    input  logic [4:0]  inst_rs1,
    input  logic [4:0]  inst_rs2,
    input  logic [2:0]  inst_funct3,
    input  logic [6:0]  inst_funct7,
    input  logic [31:0] inst_imm,
    input  logic [31:0] rval1,
    input  logic [31:0] rval2,

    output logic        mem_req_vld,
    output logic [31:0] mem_req_addr,
    output logic        mem_req_wen,
    output logic [31:0] mem_req_data
);

    takefive_pkg::r2e_t r2e;
    assign r2e.pc          = 32'b0;
    assign r2e.vld         = inst_vld;
    assign r2e.inst.opc    = takefive_pkg::opc_t'(inst_opc);
    assign r2e.inst.rd     = inst_rd;
    assign r2e.inst.rs1    = inst_rs1;
    assign r2e.inst.rs2    = inst_rs2;
    assign r2e.inst.funct3 = inst_funct3;
    assign r2e.inst.funct7 = takefive_pkg::f7_t'(inst_funct7);
    assign r2e.inst.imm    = inst_imm;
    assign r2e.rvals.rval1 = rval1;
    assign r2e.rvals.rval2 = rval2;

    takefive_pkg::mem_req_t mem_req;

    mem u_mem(
        .r2e     (r2e    ),
        .mem_req (mem_req)
    );

    assign mem_req_vld  = mem_req.vld;
    assign mem_req_addr = mem_req.addr;
    assign mem_req_wen  = mem_req.wen;
    assign mem_req_data = mem_req.data;

endmodule
