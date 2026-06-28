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
    input  logic [31:0] mem_data,

    output logic [4:0]  rfwb_rd,
    output logic        rfwb_wen,
    output logic [31:0] rfwb_wdata
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

    logic [31:0] alu_out;

    alu u_alu(
        .r2e     (r2e    ),
        .alu_out (alu_out)
    );

    takefive_pkg::e2w_t e2w;
    assign e2w.vld      = r2e.vld;
    assign e2w.pc       = r2e.pc;
    assign e2w.inst     = r2e.inst;
    assign e2w.rvals    = r2e.rvals;
    assign e2w.alu_out  = alu_out;
    assign e2w.mem_data = mem_data;

    takefive_pkg::rfwb_t rfwb;

    wb u_wb(
        .e2w  (e2w ),
        .rfwb (rfwb)
    );

    assign rfwb_rd    = rfwb.rd;
    assign rfwb_wen   = rfwb.wen;
    assign rfwb_wdata = rfwb.wdata;

endmodule
