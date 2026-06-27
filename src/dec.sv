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
            // I-type: loads, arithmetic-imm, jalr
            7'b0000011, 7'b0010011, 7'b1100111:
                d_inst.imm = {{20{f_inst[31]}}, f_inst[31:20]};

            // S-type: stores
            7'b0100011:
                d_inst.imm = {{20{f_inst[31]}}, f_inst[31:25], f_inst[11:7]};

            // B-type: branches
            7'b1100011:
                d_inst.imm = {{19{f_inst[31]}}, f_inst[31], f_inst[7], f_inst[30:25], f_inst[11:8], 1'b0};

            // U-type: lui, auipc
            7'b0110111, 7'b0010111:
                d_inst.imm = {f_inst[31:12], 12'b0};

            // J-type: jal
            7'b1101111:
                d_inst.imm = {{11{f_inst[31]}}, f_inst[31], f_inst[19:12], f_inst[20], f_inst[30:21], 1'b0};

            default:
                d_inst.imm = 32'b0;
        endcase
    end

    // Valid bit: set for legitimate RV32I encodings
    always_comb begin
        case (f_inst[6:0])
            // R-type
            7'b0110011:
                case (f_inst[14:12])
                    3'b000, 3'b101: d_inst.valid = (f_inst[31:25] == 7'b0000000)
                                                 || (f_inst[31:25] == 7'b0100000);
                    default:        d_inst.valid = (f_inst[31:25] == 7'b0000000);
                endcase

            // I-type arithmetic
            7'b0010011:
                case (f_inst[14:12])
                    3'b001:  d_inst.valid = (f_inst[31:25] == 7'b0000000);
                    3'b101:  d_inst.valid = (f_inst[31:25] == 7'b0000000)
                                          || (f_inst[31:25] == 7'b0100000);
                    default: d_inst.valid = 1'b1;
                endcase

            // Loads
            7'b0000011:
                d_inst.valid = (f_inst[14:12] != 3'b011)
                            && (f_inst[14:12] != 3'b110)
                            && (f_inst[14:12] != 3'b111);

            // Stores
            7'b0100011:
                d_inst.valid = (f_inst[14:12] == 3'b000)
                            || (f_inst[14:12] == 3'b001)
                            || (f_inst[14:12] == 3'b010);

            // Branches
            7'b1100011:
                d_inst.valid = (f_inst[14:12] != 3'b010)
                            && (f_inst[14:12] != 3'b011);

            // JALR
            7'b1100111:
                d_inst.valid = (f_inst[14:12] == 3'b000);

            // LUI, AUIPC
            7'b0110111, 7'b0010111:
                d_inst.valid = 1'b1;

            // JAL
            7'b1101111:
                d_inst.valid = 1'b1;

            // FENCE
            7'b0001111:
                d_inst.valid = (f_inst[14:12] == 3'b000);

            // ECALL, EBREAK
            7'b1110011:
                d_inst.valid = (f_inst[14:12] == 3'b000);

            default:
                d_inst.valid = 1'b0;
        endcase
    end

endmodule
