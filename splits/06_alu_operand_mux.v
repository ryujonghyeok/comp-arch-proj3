`include "cpu_github_modules/cpu_defs.vh"

// Diagram block: MB mux
//
// Selects ALU input B:
//   ALUSrc == 0 -> register value
//   ALUSrc == 1 -> sign-extended immediate
module ALUOperandMux(
    input ALUSrc,
    input [`WORD_SIZE - 1:0] reg_data_b,
    input [`WORD_SIZE - 1:0] immediate,
    output [`WORD_SIZE - 1:0] alu_b
);

    assign alu_b = ALUSrc ? immediate : reg_data_b;

endmodule

