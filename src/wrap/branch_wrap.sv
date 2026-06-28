`include "common.svh"

module branch_wrap (
    input  logic [31:0] pc,
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

    output logic        nxt_pc_vld,
    output logic [31:0] nxt_pc_pc,
    output logic [31:0] nxt_pc_nxt_pc
);

    takefive_pkg::r2e_t r2e;
    assign r2e.pc          = pc;
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

    takefive_pkg::nxt_pc_t nxt_pc;

    branch u_branch(
        .r2e    (r2e   ),
        .nxt_pc (nxt_pc)
    );

    assign nxt_pc_vld    = nxt_pc.vld;
    assign nxt_pc_pc     = nxt_pc.pc;
    assign nxt_pc_nxt_pc = nxt_pc.nxt_pc;

endmodule
