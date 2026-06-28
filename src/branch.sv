`include "common.svh"

module branch
(
    input  takefive_pkg::r2e_t    r2e,

    output takefive_pkg::nxt_pc_t nxt_pc
);

    logic cond;

    always_comb begin
        case (r2e.inst.funct3)
            takefive_pkg::F3_BEQ:  cond = (r2e.rvals.rval1 == r2e.rvals.rval2);
            takefive_pkg::F3_BNE:  cond = (r2e.rvals.rval1 != r2e.rvals.rval2);
            takefive_pkg::F3_BLT:  cond = ($signed(r2e.rvals.rval1) <  $signed(r2e.rvals.rval2));
            takefive_pkg::F3_BGE:  cond = ($signed(r2e.rvals.rval1) >= $signed(r2e.rvals.rval2));
            takefive_pkg::F3_BLTU: cond = (r2e.rvals.rval1 <  r2e.rvals.rval2);
            takefive_pkg::F3_BGEU: cond = (r2e.rvals.rval1 >= r2e.rvals.rval2);
            default:               cond = 1'b0;
        endcase
    end

    always_comb begin
        nxt_pc.vld    = 1'b0;
        nxt_pc.pc     = r2e.pc;
        nxt_pc.nxt_pc = 32'b0;

        if (r2e.vld) begin
            case (r2e.inst.opc)
                takefive_pkg::OPC_BRANCH: begin
                    nxt_pc.vld    = cond;
                    nxt_pc.nxt_pc = r2e.pc + r2e.inst.imm;
                end

                takefive_pkg::OPC_JAL: begin
                    nxt_pc.vld    = 1'b1;
                    nxt_pc.nxt_pc = r2e.pc + r2e.inst.imm;
                end

                takefive_pkg::OPC_JALR: begin
                    nxt_pc.vld    = 1'b1;
                    nxt_pc.nxt_pc = (r2e.rvals.rval1 + r2e.inst.imm) & ~32'd1;
                end

                default: ;
            endcase
        end
    end

endmodule
