`include "cpu_github_modules/cpu_defs.vh"

// Diagram block: SE
//
// In cpu_github.v, this logic is inline:
//
//   {{8{instruction[7]}}, instruction[7:0]}
//
// This split module makes that diagram block explicit.
module SignExtend8To16(
    input [7:0] imm8,
    output [`WORD_SIZE - 1:0] imm16
);

    assign imm16 = {{8{imm8[7]}}, imm8};

endmodule

