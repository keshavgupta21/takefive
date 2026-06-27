`include "common.svh"

module mem #(
    parameter DEBUG_EN = 0
)(
    input  takefive_pkg::inst_t    inst,
    input  takefive_pkg::rvals_t   rvals,

    output takefive_pkg::mem_req_t mem_req,

    input  logic                   dbg_pause
);

    always_comb begin
        mem_req.vld  = 1'b0;
        mem_req.addr = rvals.rval1 + inst.imm;
        mem_req.wen  = 1'b0;
        mem_req.data = rvals.rval2;

        if (inst.vld && (!DEBUG_EN || !dbg_pause)) begin
            case (inst.opc)
                takefive_pkg::OPC_LOAD: begin
                    mem_req.vld = 1'b1;
                    mem_req.wen = 1'b0;
                end

                takefive_pkg::OPC_STORE: begin
                    mem_req.vld = 1'b1;
                    mem_req.wen = 1'b1;
                end

                default: ;
            endcase
        end
    end

endmodule
