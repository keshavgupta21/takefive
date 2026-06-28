`include "common.svh"

module exe
(
    input  takefive_pkg::r2e_t     r2e,

    input  takefive_pkg::mem_rsp_t dmem_rsp,

    output takefive_pkg::rfwb_t    rfwb
);

    function automatic logic [31:0] alu(
        input logic [31:0] op_a,
        input logic [31:0] op_b,
        input logic [2:0]  funct3,
        input logic        sub,
        input logic        ari
    );
        case (funct3)
            takefive_pkg::F3_ADD:  alu = sub ? op_a - op_b : op_a + op_b;
            takefive_pkg::F3_SLL:  alu = op_a << op_b[4:0];
            takefive_pkg::F3_SLT:  alu = {31'b0, $signed(op_a) < $signed(op_b)};
            takefive_pkg::F3_SLTU: alu = {31'b0, op_a < op_b};
            takefive_pkg::F3_XOR:  alu = op_a ^ op_b;
            takefive_pkg::F3_SR:   alu = ari ? $signed($signed(op_a) >>> op_b[4:0])
                                             : op_a >> op_b[4:0];
            takefive_pkg::F3_OR:   alu = op_a | op_b;
            takefive_pkg::F3_AND:  alu = op_a & op_b;
            default:               alu = 32'b0;
        endcase
    endfunction

    logic [31:0] alu_b;
    assign alu_b = (r2e.inst.opc == takefive_pkg::OPC_REG) ? r2e.rvals.rval2 : r2e.inst.imm;

    logic sub;
    assign sub = (r2e.inst.opc == takefive_pkg::OPC_REG) & (r2e.inst.funct7 == takefive_pkg::F7_ALT);

    logic ari;
    assign ari = (r2e.inst.funct7 == takefive_pkg::F7_ALT);

    logic [31:0] alu_out;
    assign alu_out = alu(r2e.rvals.rval1, alu_b, r2e.inst.funct3, sub, ari);

    always_comb begin
        rfwb.rd    = r2e.inst.rd;
        rfwb.wen   = 1'b0;
        rfwb.wdata = 32'b0;

        if (r2e.vld) begin
            case (r2e.inst.opc)
                takefive_pkg::OPC_REG, takefive_pkg::OPC_IMM: begin
                    rfwb.wen   = 1'b1;
                    rfwb.wdata = alu_out;
                end

                takefive_pkg::OPC_LUI: begin
                    rfwb.wen   = 1'b1;
                    rfwb.wdata = r2e.inst.imm;
                end

                takefive_pkg::OPC_AUIPC: begin
                    rfwb.wen   = 1'b1;
                    rfwb.wdata = r2e.pc + r2e.inst.imm;
                end

                takefive_pkg::OPC_JAL: begin
                    rfwb.wen   = 1'b1;
                    rfwb.wdata = r2e.pc + 32'd4;
                end

                takefive_pkg::OPC_JALR: begin
                    rfwb.wen   = 1'b1;
                    rfwb.wdata = r2e.pc + 32'd4;
                end

                takefive_pkg::OPC_LOAD: begin
                    rfwb.wen   = 1'b1;
                    rfwb.wdata = dmem_rsp.data;
                end

                default: ;
            endcase
        end
    end

endmodule
