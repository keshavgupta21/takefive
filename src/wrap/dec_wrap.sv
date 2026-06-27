`include "common.svh"

module dec_wrap (
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

    takefive_pkg::inst_t d_inst;

    dec u_dec(
        .f_pc      (f_pc ),
        .f_inst    (f_inst),
        .d_pc      (d_pc  ),
        .d_inst    (d_inst),
        .dbg_pause (1'b0  )
    );

    assign d_inst_vld    = d_inst.vld;
    assign d_inst_opc    = d_inst.opc;
    assign d_inst_rd     = d_inst.rd;
    assign d_inst_rs1    = d_inst.rs1;
    assign d_inst_rs2    = d_inst.rs2;
    assign d_inst_funct3 = d_inst.funct3;
    assign d_inst_funct7 = d_inst.funct7;
    assign d_inst_imm    = d_inst.imm;

endmodule
