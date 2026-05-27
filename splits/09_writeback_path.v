`include "cpu_github_modules/cpu_defs.vh"

// Diagram block: MD mux / writeback path
//
// In the full diagram, MD selects whether RF receives ALU output or data
// memory output.
//
// In cpu_github.v, data memory is not implemented, so writeback is simply:
//
//   RF_write = ALU_C;
//
// This module makes that simplified path explicit.
module WriteBackPath(
    input [`WORD_SIZE - 1:0] alu_result,
    output [`WORD_SIZE - 1:0] rf_write_data
);

    assign rf_write_data = alu_result;

endmodule

