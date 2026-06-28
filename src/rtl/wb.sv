`include "common.svh"

module wb
(
    input  takefive_pkg::e2w_t   e2w,
    input  takefive_pkg::mem_rsp_t dmem_rsp,

    output takefive_pkg::rf_wr_req_t rf_wr_req,
    output logic                stall
);

    always_comb begin
        rf_wr_req.rd    = e2w.inst.rd;
        rf_wr_req.wen   = 1'b0;
        rf_wr_req.wdata = 32'b0;
        stall      = 0;

        if (e2w.vld) begin
            case (e2w.inst.opc)
                takefive_pkg::OPC_REG, takefive_pkg::OPC_IMM: begin
                    rf_wr_req.wen   = 1'b1;
                    rf_wr_req.wdata = e2w.alu_out;
                end

                takefive_pkg::OPC_LUI: begin
                    rf_wr_req.wen   = 1'b1;
                    rf_wr_req.wdata = e2w.inst.imm;
                end

                takefive_pkg::OPC_AUIPC: begin
                    rf_wr_req.wen   = 1'b1;
                    rf_wr_req.wdata = e2w.pc + e2w.inst.imm;
                end

                takefive_pkg::OPC_JAL: begin
                    rf_wr_req.wen   = 1'b1;
                    rf_wr_req.wdata = e2w.pc + 32'd4;
                end

                takefive_pkg::OPC_JALR: begin
                    rf_wr_req.wen   = 1'b1;
                    rf_wr_req.wdata = e2w.pc + 32'd4;
                end

                takefive_pkg::OPC_LOAD: begin
                    rf_wr_req.wen   = dmem_rsp.vld;
                    rf_wr_req.wdata = dmem_rsp.data;
                    stall      = !dmem_rsp.vld;
                end

                default: ;
            endcase
        end
    end
endmodule
