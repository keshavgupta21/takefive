`include "common.svh"

module bypass
(
    input  takefive_pkg::inst_t  inst,
    input  takefive_pkg::rvals_t rd_rvals,
    input  takefive_pkg::r2e_t   r2e,
    input  takefive_pkg::rfwb_t  rfwb,

    output takefive_pkg::rvals_t byp_rvals,
    output logic                 stall
);

    logic rs1_r2e, rs1_wb;
    logic rs2_r2e, rs2_wb;

    assign rs1_r2e = (inst.rs1 != 5'b0) && r2e.vld && (r2e.inst.rd == inst.rs1);
    assign rs1_wb  = (inst.rs1 != 5'b0) && rfwb.wen && (rfwb.rd == inst.rs1);
    assign rs2_r2e = inst.rs2_vld && (inst.rs2 != 5'b0) && r2e.vld && (r2e.inst.rd == inst.rs2);
    assign rs2_wb  = inst.rs2_vld && (inst.rs2 != 5'b0) && rfwb.wen && (rfwb.rd == inst.rs2);

    assign stall = rs1_r2e || rs2_r2e;

    always_comb begin
        byp_rvals = rd_rvals;
        if (!stall) begin
            if (rs1_wb) byp_rvals.rval1 = rfwb.wdata;
            if (rs2_wb) byp_rvals.rval2 = rfwb.wdata;
        end
    end

endmodule
