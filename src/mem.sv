`include "common.svh"

module mem
(
    input  takefive_pkg::r2e_t     r2e,

    output takefive_pkg::mem_req_t mem_req
);

    always_comb begin
        mem_req.vld  = 1'b0;
        mem_req.addr = r2e.rvals.rval1 + r2e.inst.imm;
        mem_req.wen  = 1'b0;
        mem_req.data = r2e.rvals.rval2;

        if (r2e.inst.vld) begin
            case (r2e.inst.opc)
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
