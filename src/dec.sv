`include "common.svh"

module dec
(
    input  takefive_pkg::fetch_t fetch,
    output logic [31:0]          d_pc,
    output takefive_pkg::inst_t  d_inst
);

    assign d_pc          = fetch.pc;
    assign d_inst.opc    = fetch.inst[6:0];
    assign d_inst.rd     = fetch.inst[11:7];
    assign d_inst.rs1    = fetch.inst[19:15];
    assign d_inst.rs2    = fetch.inst[24:20];
    assign d_inst.funct3 = fetch.inst[14:12];
    assign d_inst.funct7 = fetch.inst[31:25];

    always_comb begin
        case (d_inst.opc)
            takefive_pkg::OPC_LOAD, takefive_pkg::OPC_IMM, takefive_pkg::OPC_JALR:
                d_inst.imm = {{20{fetch.inst[31]}}, fetch.inst[31:20]};

            takefive_pkg::OPC_STORE:
                d_inst.imm = {{20{fetch.inst[31]}}, fetch.inst[31:25], fetch.inst[11:7]};

            takefive_pkg::OPC_BRANCH:
                d_inst.imm = {{19{fetch.inst[31]}}, fetch.inst[31], fetch.inst[7], fetch.inst[30:25], fetch.inst[11:8], 1'b0};

            takefive_pkg::OPC_LUI, takefive_pkg::OPC_AUIPC:
                d_inst.imm = {fetch.inst[31:12], 12'b0};

            takefive_pkg::OPC_JAL:
                d_inst.imm = {{11{fetch.inst[31]}}, fetch.inst[31], fetch.inst[19:12], fetch.inst[20], fetch.inst[30:21], 1'b0};

            default:
                d_inst.imm = 32'b0;
        endcase
    end

    always_comb begin
        case (d_inst.opc)
            takefive_pkg::OPC_REG:
                case (d_inst.funct3)
                    takefive_pkg::F3_ADD, takefive_pkg::F3_SR:
                        d_inst.vld = (d_inst.funct7 == takefive_pkg::F7_BASE)
                                  || (d_inst.funct7 == takefive_pkg::F7_ALT);
                    default:
                        d_inst.vld = (d_inst.funct7 == takefive_pkg::F7_BASE);
                endcase

            takefive_pkg::OPC_IMM:
                case (d_inst.funct3)
                    takefive_pkg::F3_SLL:
                        d_inst.vld = (d_inst.funct7 == takefive_pkg::F7_BASE);
                    takefive_pkg::F3_SR:
                        d_inst.vld = (d_inst.funct7 == takefive_pkg::F7_BASE)
                                  || (d_inst.funct7 == takefive_pkg::F7_ALT);
                    default:
                        d_inst.vld = 1'b1;
                endcase

            takefive_pkg::OPC_LOAD:
                d_inst.vld = (d_inst.funct3 == takefive_pkg::F3_W);

            takefive_pkg::OPC_STORE:
                d_inst.vld = (d_inst.funct3 == takefive_pkg::F3_W);

            takefive_pkg::OPC_BRANCH:
                d_inst.vld = (d_inst.funct3 == takefive_pkg::F3_BEQ)
                          || (d_inst.funct3 == takefive_pkg::F3_BNE)
                          || (d_inst.funct3 == takefive_pkg::F3_BLT)
                          || (d_inst.funct3 == takefive_pkg::F3_BGE)
                          || (d_inst.funct3 == takefive_pkg::F3_BLTU)
                          || (d_inst.funct3 == takefive_pkg::F3_BGEU);

            takefive_pkg::OPC_JALR:
                d_inst.vld = (d_inst.funct3 == takefive_pkg::F3_ADD);

            takefive_pkg::OPC_LUI, takefive_pkg::OPC_AUIPC:
                d_inst.vld = 1'b1;

            takefive_pkg::OPC_JAL:
                d_inst.vld = 1'b1;

            takefive_pkg::OPC_FENCE:
                d_inst.vld = (d_inst.funct3 == takefive_pkg::F3_ADD);

            takefive_pkg::OPC_SYSTEM:
                d_inst.vld = (d_inst.funct3 == takefive_pkg::F3_ADD);

            default:
                d_inst.vld = 1'b0;
        endcase

        d_inst.vld = d_inst.vld && fetch.vld;
    end

endmodule
