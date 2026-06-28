`include "common.svh"

module dec_wrap (
    input  logic        f_vld,
    input  logic [31:0] f_pc,
    input  logic [31:0] f_inst,
    output logic [31:0] d_pc,
    output logic        d_inst_vld,
    output logic [6:0]  d_inst_opc,
    output logic [4:0]  d_inst_rd,
    output logic [4:0]  d_inst_rs1,
    output logic [4:0]  d_inst_rs2,
    output logic [2:0]  d_inst_funct3,
    output logic [6:0]  d_inst_funct7,
    output logic [31:0] d_inst_imm
);

    takefive_pkg::f2d_t f2d;
    assign f2d.vld  = f_vld;
    assign f2d.pc   = f_pc;
    assign f2d.inst = f_inst;

    takefive_pkg::d2r_t d2r;

    dec u_dec(
        .f2d (f2d),
        .d2r (d2r)
    );

    assign d_pc          = d2r.pc;
    assign d_inst_vld    = d2r.inst.vld;
    assign d_inst_opc    = d2r.inst.opc;
    assign d_inst_rd     = d2r.inst.rd;
    assign d_inst_rs1    = d2r.inst.rs1;
    assign d_inst_rs2    = d2r.inst.rs2;
    assign d_inst_funct3 = d2r.inst.funct3;
    assign d_inst_funct7 = d2r.inst.funct7;
    assign d_inst_imm    = d2r.inst.imm;

endmodule
