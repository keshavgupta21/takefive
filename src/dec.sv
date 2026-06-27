`include "common.svh"

module dec
(
    input  logic [31:0]         f_pc,
    input  logic [31:0]         f_inst,
    output logic [31:0]         d_pc,
    output takefive_pkg::inst_t d_inst
);

    assign d_pc          = f_pc;
    assign d_inst.opc    = f_inst[6:0];
    assign d_inst.rd     = f_inst[11:7];
    assign d_inst.rs1    = f_inst[19:15];
    assign d_inst.rs2    = f_inst[24:20];
    assign d_inst.funct3 = f_inst[14:12];
    assign d_inst.funct7 = f_inst[31:25];

    always_comb begin
        case (f_inst[6:0])
            takefive_pkg::OPC_LOAD, takefive_pkg::OPC_IMM, takefive_pkg::OPC_JALR:
                d_inst.imm = {{20{f_inst[31]}}, f_inst[31:20]};

            takefive_pkg::OPC_STORE:
                d_inst.imm = {{20{f_inst[31]}}, f_inst[31:25], f_inst[11:7]};

            takefive_pkg::OPC_BRANCH:
                d_inst.imm = {{19{f_inst[31]}}, f_inst[31], f_inst[7], f_inst[30:25], f_inst[11:8], 1'b0};

            takefive_pkg::OPC_LUI, takefive_pkg::OPC_AUIPC:
                d_inst.imm = {f_inst[31:12], 12'b0};

            takefive_pkg::OPC_JAL:
                d_inst.imm = {{11{f_inst[31]}}, f_inst[31], f_inst[19:12], f_inst[20], f_inst[30:21], 1'b0};

            default:
                d_inst.imm = 32'b0;
        endcase
    end

    always_comb begin
        case (f_inst[6:0])
            takefive_pkg::OPC_REG:
                case (f_inst[14:12])
                    takefive_pkg::F3_ADD, takefive_pkg::F3_SR:
                        d_inst.vld = (f_inst[31:25] == takefive_pkg::F7_BASE)
                                  || (f_inst[31:25] == takefive_pkg::F7_ALT);
                    default:
                        d_inst.vld = (f_inst[31:25] == takefive_pkg::F7_BASE);
                endcase

            takefive_pkg::OPC_IMM:
                case (f_inst[14:12])
                    takefive_pkg::F3_SLL:
                        d_inst.vld = (f_inst[31:25] == takefive_pkg::F7_BASE);
                    takefive_pkg::F3_SR:
                        d_inst.vld = (f_inst[31:25] == takefive_pkg::F7_BASE)
                                  || (f_inst[31:25] == takefive_pkg::F7_ALT);
                    default:
                        d_inst.vld = 1'b1;
                endcase

            takefive_pkg::OPC_LOAD:
                d_inst.vld = (f_inst[14:12] != takefive_pkg::F3_SLTU)
                          && (f_inst[14:12] != takefive_pkg::F3_OR)
                          && (f_inst[14:12] != takefive_pkg::F3_AND);

            takefive_pkg::OPC_STORE:
                d_inst.vld = (f_inst[14:12] == takefive_pkg::F3_B)
                          || (f_inst[14:12] == takefive_pkg::F3_H)
                          || (f_inst[14:12] == takefive_pkg::F3_W);

            takefive_pkg::OPC_BRANCH:
                d_inst.vld = (f_inst[14:12] != takefive_pkg::F3_SLT)
                          && (f_inst[14:12] != takefive_pkg::F3_SLTU);

            takefive_pkg::OPC_JALR:
                d_inst.vld = (f_inst[14:12] == takefive_pkg::F3_ADD);

            takefive_pkg::OPC_LUI, takefive_pkg::OPC_AUIPC:
                d_inst.vld = 1'b1;

            takefive_pkg::OPC_JAL:
                d_inst.vld = 1'b1;

            takefive_pkg::OPC_FENCE:
                d_inst.vld = (f_inst[14:12] == takefive_pkg::F3_ADD);

            takefive_pkg::OPC_SYSTEM:
                d_inst.vld = (f_inst[14:12] == takefive_pkg::F3_ADD);

            default:
                d_inst.vld = 1'b0;
        endcase
    end

endmodule
