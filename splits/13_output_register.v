`include "cpu_github_modules/cpu_defs.vh"

// Captures the ALU result for the WWD-visible output port.
module OutputRegister(
    input clk,
    input [`WORD_SIZE - 1:0] input_data,
    output reg [`WORD_SIZE - 1:0] output_data
);

    always @(posedge clk) begin
        output_data = input_data;
    end

endmodule

