`include "common.svh"

module branch #(
    parameter DEBUG_EN = 0
)(
    input  logic [31:0]           pc,
    input  takefive_pkg::inst_t   inst,
    input  takefive_pkg::rvals_t  rvals,

    output takefive_pkg::nxt_pc_t nxt_pc,

    input  logic                  dbg_pause
);

    logic cond;

    always_comb begin
        case (inst.funct3)
            takefive_pkg::F3_BEQ:  cond = (rvals.rval1 == rvals.rval2);
            takefive_pkg::F3_BNE:  cond = (rvals.rval1 != rvals.rval2);
            takefive_pkg::F3_BLT:  cond = ($signed(rvals.rval1) <  $signed(rvals.rval2));
            takefive_pkg::F3_BGE:  cond = ($signed(rvals.rval1) >= $signed(rvals.rval2));
            takefive_pkg::F3_BLTU: cond = (rvals.rval1 <  rvals.rval2);
            takefive_pkg::F3_BGEU: cond = (rvals.rval1 >= rvals.rval2);
            default:               cond = 1'b0;
        endcase
    end

    always_comb begin
        nxt_pc.vld    = 1'b0;
        nxt_pc.pc     = pc;
        nxt_pc.nxt_pc = 32'b0;

        if (inst.vld && (!DEBUG_EN || !dbg_pause)) begin
            case (inst.opc)
                takefive_pkg::OPC_BRANCH: begin
                    nxt_pc.vld    = cond;
                    nxt_pc.nxt_pc = pc + inst.imm;
                end

                takefive_pkg::OPC_JAL: begin
                    nxt_pc.vld    = 1'b1;
                    nxt_pc.nxt_pc = pc + inst.imm;
                end

                takefive_pkg::OPC_JALR: begin
                    nxt_pc.vld    = 1'b1;
                    nxt_pc.nxt_pc = (rvals.rval1 + inst.imm) & ~32'd1;
                end

                default: ;
            endcase
        end
    end

endmodule
