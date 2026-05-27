`include "cpu_github_modules/cpu_defs.vh"

// Counts CPU clock cycles/instructions, matching cpu_github.v behavior.
module NumInstCounter(
    input clk,
    input reset_n,
    output reg [`WORD_SIZE - 1:0] num_inst
);

    always @(posedge clk) begin
        if (reset_n == 1'b0) begin
            num_inst <= 0;
        end
        else begin
            num_inst <= num_inst + 1;
        end
    end

endmodule

