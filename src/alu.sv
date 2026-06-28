`include "common.svh"

module alu
(
    input  takefive_pkg::r2e_t r2e,

    output logic [31:0]        alu_out
);

    function automatic logic [31:0] compute(
        input logic [31:0] op_a,
        input logic [31:0] op_b,
        input logic [2:0]  funct3,
        input logic        sub,
        input logic        ari
    );
        case (funct3)
            takefive_pkg::F3_ADD:  compute = sub ? op_a - op_b : op_a + op_b;
            takefive_pkg::F3_SLL:  compute = op_a << op_b[4:0];
            takefive_pkg::F3_SLT:  compute = {31'b0, $signed(op_a) < $signed(op_b)};
            takefive_pkg::F3_SLTU: compute = {31'b0, op_a < op_b};
            takefive_pkg::F3_XOR:  compute = op_a ^ op_b;
            takefive_pkg::F3_SR:   compute = ari ? $signed($signed(op_a) >>> op_b[4:0])
                                                 : op_a >> op_b[4:0];
            takefive_pkg::F3_OR:   compute = op_a | op_b;
            takefive_pkg::F3_AND:  compute = op_a & op_b;
            default:               compute = 32'b0;
        endcase
    endfunction

    logic [31:0] alu_b;
    assign alu_b = (r2e.inst.opc == takefive_pkg::OPC_REG) ? r2e.rvals.rval2 : r2e.inst.imm;

    logic sub;
    assign sub = (r2e.inst.opc == takefive_pkg::OPC_REG) & (r2e.inst.funct7 == takefive_pkg::F7_ALT);

    logic ari;
    assign ari = (r2e.inst.funct7 == takefive_pkg::F7_ALT);

    assign alu_out = compute(r2e.rvals.rval1, alu_b, r2e.inst.funct3, sub, ari);

endmodule
