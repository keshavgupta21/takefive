`include "common.svh"

module branch
(
    input  takefive_pkg::r2e_t   r2e,

    output takefive_pkg::annul_t annul
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
        annul.annul  = 1'b0;
        annul.pc     = r2e.pc;
        annul.nxt_pc = 32'b0;

        if (r2e.vld) begin
            case (r2e.inst.opc)
                takefive_pkg::OPC_BRANCH: begin
                    annul.annul  = cond;
                    annul.nxt_pc = r2e.pc + r2e.inst.imm;
                end

                takefive_pkg::OPC_JAL: begin
                    annul.annul  = 1'b1;
                    annul.nxt_pc = r2e.pc + r2e.inst.imm;
                end

                takefive_pkg::OPC_JALR: begin
                    annul.annul  = 1'b1;
                    annul.nxt_pc = (r2e.rvals.rval1 + r2e.inst.imm) & ~32'd1;
                end

                default: ;
            endcase
        end
    end

endmodule
