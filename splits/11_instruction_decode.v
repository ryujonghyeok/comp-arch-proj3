`include "cpu_github_modules/cpu_defs.vh"

// Splits a 16-bit instruction into the fields used by the diagram blocks.
module InstructionDecode(
    input [`WORD_SIZE - 1:0] instruction,
    output [`opcode_length - 1:0] opcode,
    output [`func_code_length - 1:0] func_code,
    output [`reg_addr_length - 1:0] rs,
    output [`reg_addr_length - 1:0] rt,
    output [`reg_addr_length - 1:0] rd,
    output [7:0] imm8,
    output [`Jump_target_length - 1:0] J_target
);

    assign opcode = instruction[`opcode_left : `opcode_right];
    assign func_code = instruction[`func_code_left : `func_code_right];
    assign rs = instruction[`rs_left : `rs_right];
    assign rt = instruction[`rt_left : `rt_right];
    assign rd = instruction[`rd_left : `rd_right];
    assign imm8 = instruction[`immediate_left : `immediate_right];
    assign J_target = instruction[`target_left : `target_right];

endmodule

