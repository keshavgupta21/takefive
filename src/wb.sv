`include "common.svh"

module wb
(
    input  takefive_pkg::e2w_t  e2w,

    output takefive_pkg::rfwb_t rfwb
);

    always_comb begin
        rfwb.rd    = e2w.inst.rd;
        rfwb.wen   = 1'b0;
        rfwb.wdata = 32'b0;

        if (e2w.vld) begin
            case (e2w.inst.opc)
                takefive_pkg::OPC_REG, takefive_pkg::OPC_IMM: begin
                    rfwb.wen   = 1'b1;
                    rfwb.wdata = e2w.alu_out;
                end

                takefive_pkg::OPC_LUI: begin
                    rfwb.wen   = 1'b1;
                    rfwb.wdata = e2w.inst.imm;
                end

                takefive_pkg::OPC_AUIPC: begin
                    rfwb.wen   = 1'b1;
                    rfwb.wdata = e2w.pc + e2w.inst.imm;
                end

                takefive_pkg::OPC_JAL: begin
                    rfwb.wen   = 1'b1;
                    rfwb.wdata = e2w.pc + 32'd4;
                end

                takefive_pkg::OPC_JALR: begin
                    rfwb.wen   = 1'b1;
                    rfwb.wdata = e2w.pc + 32'd4;
                end

                takefive_pkg::OPC_LOAD: begin
                    rfwb.wen   = 1'b1;
                    rfwb.wdata = e2w.mem_data;
                end

                default: ;
            endcase
        end
    end

endmodule
