`include "common.svh"

module branch_wrap (
    input  wire [31:0] pc,
    input  wire        inst_vld,
    input  wire [6:0]  inst_opc,
    input  wire [4:0]  inst_rd,
    input  wire [4:0]  inst_rs1,
    input  wire [4:0]  inst_rs2,
    input  wire [2:0]  inst_funct3,
    input  wire [6:0]  inst_funct7,
    input  wire [31:0] inst_imm,
    input  wire [31:0] rval1,
    input  wire [31:0] rval2,

    output wire        annul_annul,
    output wire [31:0] annul_pc,
    output wire [31:0] annul_nxt_pc
);

    takefive_pkg::r2e_t r2e;
    assign r2e.pc          = pc;
    assign r2e.vld         = inst_vld;
    assign r2e.inst.opc    = takefive_pkg::opc_t'(inst_opc);
    assign r2e.inst.rd     = inst_rd;
    assign r2e.inst.rs1    = inst_rs1;
    assign r2e.inst.rs2     = inst_rs2;
    assign r2e.inst.rs2_vld = 1'b1;
    assign r2e.inst.funct3  = inst_funct3;
    assign r2e.inst.funct7 = takefive_pkg::f7_t'(inst_funct7);
    assign r2e.inst.imm    = inst_imm;
    assign r2e.rvals.rval1 = rval1;
    assign r2e.rvals.rval2 = rval2;

    takefive_pkg::annul_t annul;

    branch u_branch(
        .r2e   (r2e  ),
        .annul (annul)
    );

    assign annul_annul  = annul.annul;
    assign annul_pc     = annul.pc;
    assign annul_nxt_pc = annul.nxt_pc;

endmodule
