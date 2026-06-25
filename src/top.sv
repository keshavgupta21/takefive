module top (
    input  logic clk,
    input  logic rst_n,
    input  logic [7:0] in_data,
    output logic [7:0] out_data
);

    logic [7:0] data_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_reg <= 8'h00;
        else
            data_reg <= in_data;
    end

    assign out_data = data_reg;

endmodule
