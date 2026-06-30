`include "common.svh"

module mem
(
    input  takefive_pkg::r2e_t     r2e,

    input  logic                   dmem_rdy,
    output takefive_pkg::mem_req_t mem_req,

    output logic                   stall
);

    always_comb begin
        mem_req.vld  = 1'b0;
        mem_req.wen  = 1'b0;
        mem_req.addr = r2e.rvals.rval1 + r2e.inst.imm;
        mem_req.data = r2e.rvals.rval2;
        mem_req.uid  = r2e.rvals.rval1 + r2e.inst.imm;
        stall        = 0;

        if (r2e.vld) begin
            case (r2e.inst.opc)
                takefive_pkg::OPC_LOAD: begin
                    mem_req.vld = dmem_rdy;
                    mem_req.wen = 1'b0;
                    stall       = !dmem_rdy;
                end

                takefive_pkg::OPC_STORE: begin
                    mem_req.vld = dmem_rdy;
                    mem_req.wen = 1'b1;
                    stall       = !dmem_rdy;
                end

                default: ;
            endcase
        end
    end

endmodule
