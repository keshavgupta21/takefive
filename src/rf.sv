`include "common.svh"

module rf
(
    input  logic        clk,

    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,
    output logic [31:0] rval1,
    output logic [31:0] rval2,

    input  logic [4:0]  rd,
    input  logic        wen,
    input  logic [31:0] wdata
);

    logic [31:0] regs [0:31];

    initial begin
        regs[0] = 32'b0;
        for (int i = 1; i < 32; i++)
            regs[i] = 32'h01010101 * i;
    end

    always_ff @(posedge clk) begin
        if (wen && rd != 5'b0)
            regs[rd] <= wdata;
    end

    assign rval1 = regs[rs1];
    assign rval2 = regs[rs2];

endmodule
