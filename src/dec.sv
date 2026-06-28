`include "common.svh"

module dec
(
    input  takefive_pkg::f2d_t f2d,
    output takefive_pkg::d2r_t d2r
);

    always_comb begin
        d2r.pc          = f2d.pc;
        d2r.inst.opc    = f2d.inst[6:0];
        d2r.inst.rd     = f2d.inst[11:7];
        d2r.inst.rs1    = f2d.inst[19:15];
        d2r.inst.rs2    = f2d.inst[24:20];
        d2r.inst.funct3 = f2d.inst[14:12];
        d2r.inst.funct7 = f2d.inst[31:25];

        case (d2r.inst.opc)
            takefive_pkg::OPC_LOAD, takefive_pkg::OPC_IMM, takefive_pkg::OPC_JALR:
                d2r.inst.imm = {{20{f2d.inst[31]}}, f2d.inst[31:20]};

            takefive_pkg::OPC_STORE:
                d2r.inst.imm = {{20{f2d.inst[31]}}, f2d.inst[31:25], f2d.inst[11:7]};

            takefive_pkg::OPC_BRANCH:
                d2r.inst.imm = {{19{f2d.inst[31]}}, f2d.inst[31], f2d.inst[7], f2d.inst[30:25], f2d.inst[11:8], 1'b0};

            takefive_pkg::OPC_LUI, takefive_pkg::OPC_AUIPC:
                d2r.inst.imm = {f2d.inst[31:12], 12'b0};

            takefive_pkg::OPC_JAL:
                d2r.inst.imm = {{11{f2d.inst[31]}}, f2d.inst[31], f2d.inst[19:12], f2d.inst[20], f2d.inst[30:21], 1'b0};

            default:
                d2r.inst.imm = 32'b0;
        endcase

        case (d2r.inst.opc)
            takefive_pkg::OPC_REG:
                case (d2r.inst.funct3)
                    takefive_pkg::F3_ADD, takefive_pkg::F3_SR:
                        d2r.inst.vld = (d2r.inst.funct7 == takefive_pkg::F7_BASE)
                                    || (d2r.inst.funct7 == takefive_pkg::F7_ALT);
                    default:
                        d2r.inst.vld = (d2r.inst.funct7 == takefive_pkg::F7_BASE);
                endcase

            takefive_pkg::OPC_IMM:
                case (d2r.inst.funct3)
                    takefive_pkg::F3_SLL:
                        d2r.inst.vld = (d2r.inst.funct7 == takefive_pkg::F7_BASE);
                    takefive_pkg::F3_SR:
                        d2r.inst.vld = (d2r.inst.funct7 == takefive_pkg::F7_BASE)
                                    || (d2r.inst.funct7 == takefive_pkg::F7_ALT);
                    default:
                        d2r.inst.vld = 1'b1;
                endcase

            takefive_pkg::OPC_LOAD:
                d2r.inst.vld = (d2r.inst.funct3 == takefive_pkg::F3_W);

            takefive_pkg::OPC_STORE:
                d2r.inst.vld = (d2r.inst.funct3 == takefive_pkg::F3_W);

            takefive_pkg::OPC_BRANCH:
                d2r.inst.vld = (d2r.inst.funct3 == takefive_pkg::F3_BEQ)
                            || (d2r.inst.funct3 == takefive_pkg::F3_BNE)
                            || (d2r.inst.funct3 == takefive_pkg::F3_BLT)
                            || (d2r.inst.funct3 == takefive_pkg::F3_BGE)
                            || (d2r.inst.funct3 == takefive_pkg::F3_BLTU)
                            || (d2r.inst.funct3 == takefive_pkg::F3_BGEU);

            takefive_pkg::OPC_JALR:
                d2r.inst.vld = (d2r.inst.funct3 == takefive_pkg::F3_ADD);

            takefive_pkg::OPC_LUI, takefive_pkg::OPC_AUIPC:
                d2r.inst.vld = 1'b1;

            takefive_pkg::OPC_JAL:
                d2r.inst.vld = 1'b1;

            takefive_pkg::OPC_FENCE:
                d2r.inst.vld = (d2r.inst.funct3 == takefive_pkg::F3_ADD);

            takefive_pkg::OPC_SYSTEM:
                d2r.inst.vld = (d2r.inst.funct3 == takefive_pkg::F3_ADD);

            default:
                d2r.inst.vld = 1'b0;
        endcase

        d2r.inst.vld = d2r.inst.vld && f2d.vld;
    end

endmodule
