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

    takefive_pkg::inst_t inst;
    assign inst.vld    = inst_vld;
    assign inst.opc    = inst_opc;
    assign inst.rd     = inst_rd;
    assign inst.rs1    = inst_rs1;
    assign inst.rs2    = inst_rs2;
    assign inst.funct3 = inst_funct3;
    assign inst.funct7 = inst_funct7;
    assign inst.imm    = inst_imm;

    takefive_pkg::rvals_t rvals;
    assign rvals.rval1 = rval1;
    assign rvals.rval2 = rval2;

    takefive_pkg::nxt_pc_t nxt_pc;

    branch u_branch(
        .pc     (pc    ),
        .inst   (inst  ),
        .rvals  (rvals ),
        .nxt_pc (nxt_pc)
    );

    assign nxt_pc_vld    = nxt_pc.vld;
    assign nxt_pc_pc     = nxt_pc.pc;
    assign nxt_pc_nxt_pc = nxt_pc.nxt_pc;

endmodule
