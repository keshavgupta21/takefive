`include "common.svh"
module dec (
    f2d_intf.d f2d,
    d2r_intf.d d2r
);
    assign d2r.pc          = f2d.pc;
    assign d2r.inst.opc    = f2d.inst[6:0];
    assign d2r.inst.rd     = f2d.inst[11:7];
    assign d2r.inst.rs1    = f2d.inst[19:15];
    assign d2r.inst.rs2    = f2d.inst[24:20];
    assign d2r.inst.funct3 = f2d.inst[14:12];
    assign d2r.inst.funct7 = f2d.inst[31:25];

    always_comb begin
        case (f2d.inst[6:0])
            // I-type: loads, arithmetic-imm, jalr
            7'b0000011, 7'b0010011, 7'b1100111:
                d2r.inst.imm = {{20{f2d.inst[31]}}, f2d.inst[31:20]};

            // S-type: stores
            7'b0100011:
                d2r.inst.imm = {{20{f2d.inst[31]}}, f2d.inst[31:25], f2d.inst[11:7]};

            // B-type: branches
            7'b1100011:
                d2r.inst.imm = {{19{f2d.inst[31]}}, f2d.inst[31], f2d.inst[7], f2d.inst[30:25], f2d.inst[11:8], 1'b0};

            // U-type: lui, auipc
            7'b0110111, 7'b0010111:
                d2r.inst.imm = {f2d.inst[31:12], 12'b0};

            // J-type: jal
            7'b1101111:
                d2r.inst.imm = {{11{f2d.inst[31]}}, f2d.inst[31], f2d.inst[19:12], f2d.inst[20], f2d.inst[30:21], 1'b0};

            default:
                d2r.inst.imm = 32'b0;
        endcase
    end

endmodule
