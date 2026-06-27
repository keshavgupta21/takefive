`include "common.svh"

module exe_wrap (
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

    output logic [4:0]  rfwb_rd,
    output logic        rfwb_wen,
    output logic [31:0] rfwb_wdata
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

    takefive_pkg::rfwb_t rfwb;

    exe u_exe(
        .pc    (pc   ),
        .inst  (inst ),
        .rvals (rvals),
        .rfwb  (rfwb )
    );

    assign rfwb_rd    = rfwb.rd;
    assign rfwb_wen   = rfwb.wen;
    assign rfwb_wdata = rfwb.wdata;

endmodule
