`include "common.svh"
module dec_wrap (
    input  logic [31:0] f2d_pc,
    input  logic [31:0] f2d_inst,
    output logic [31:0] d2r_pc,
    output logic [6:0]  d2r_opc,
    output logic [4:0]  d2r_rd,
    output logic [4:0]  d2r_rs1,
    output logic [4:0]  d2r_rs2,
    output logic [2:0]  d2r_funct3,
    output logic [6:0]  d2r_funct7,
    output logic [31:0] d2r_imm
);

    f2d_intf f2d();
    d2r_intf d2r();

    assign f2d.pc   = f2d_pc;
    assign f2d.inst = f2d_inst;

    dec u_dec(.f2d(f2d.d), .d2r(d2r.d));

    assign d2r_pc     = d2r.pc;
    assign d2r_opc    = d2r.inst.opc;
    assign d2r_rd     = d2r.inst.rd;
    assign d2r_rs1    = d2r.inst.rs1;
    assign d2r_rs2    = d2r.inst.rs2;
    assign d2r_funct3 = d2r.inst.funct3;
    assign d2r_funct7 = d2r.inst.funct7;
    assign d2r_imm    = d2r.inst.imm;

endmodule
