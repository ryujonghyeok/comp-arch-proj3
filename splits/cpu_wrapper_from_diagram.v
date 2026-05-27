`include "cpu_github_modules/cpu_defs.vh"

// Wrapper CPU built from the diagram-split blocks.
//
// This file intentionally contains only top-level wiring and module calls.
// The small operations that used to be inline in cpu_github.v, such as
// instruction slicing and write-address selection, live in separate modules.
module cpu (
    output readM,
    output [`WORD_SIZE - 1:0] address,
    inout [`WORD_SIZE - 1:0] data,
    input inputReady,
    input reset_n,
    input clk,
    output [`WORD_SIZE - 1:0] num_inst,
    output [`WORD_SIZE - 1:0] output_port
);

    wire [`WORD_SIZE - 1:0] instruction_addr;
    wire [`WORD_SIZE - 1:0] instruction;

    wire [`opcode_length - 1:0] opcode;
    wire [`func_code_length - 1:0] func_code;
    wire [`reg_addr_length - 1:0] rs;
    wire [`reg_addr_length - 1:0] rt;
    wire [`reg_addr_length - 1:0] rd;
    wire [7:0] imm8;
    wire [`WORD_SIZE - 1:0] imm16;
    wire [`Jump_target_length - 1:0] J_target;

    wire RegDst;
    wire Jump;
    wire ALUSrc;
    wire RegWrite;
    wire isWWD;
    wire [3:0] ALUOp;

    wire [`reg_addr_length - 1:0] write_addr;
    wire [`WORD_SIZE - 1:0] rf_data_a;
    wire [`WORD_SIZE - 1:0] rf_data_b;
    wire [`WORD_SIZE - 1:0] rf_write_data;

    wire [`WORD_SIZE - 1:0] alu_b;
    wire [`WORD_SIZE - 1:0] alu_result;
    wire alu_cout;

    PC pc_block(
        clk,
        reset_n,
        Jump,
        J_target,
        instruction_addr
    );

    InstructionMemoryInterface inst_mem_if(
        clk,
        reset_n,
        inputReady,
        data,
        instruction_addr,
        readM,
        address,
        instruction
    );

    InstructionDecode instruction_decode(
        instruction,
        opcode,
        func_code,
        rs,
        rt,
        rd,
        imm8,
        J_target
    );

    Control control_unit(
        reset_n,
        opcode,
        func_code,
        RegDst,
        Jump,
        ALUOp,
        ALUSrc,
        RegWrite,
        isWWD
    );

    RegDstMux regdst_mux(
        RegDst,
        rt,
        rd,
        write_addr
    );

    RF register_file(
        clk,
        reset_n,
        rs,
        rf_data_a,
        rt,
        rf_data_b,
        RegWrite,
        write_addr,
        rf_write_data
    );

    SignExtend8To16 sign_extend(
        imm8,
        imm16
    );

    ALUOperandMux alu_operand_mux(
        ALUSrc,
        rf_data_b,
        imm16,
        alu_b
    );

    ALU alu_block(
        rf_data_a,
        alu_b,
        1'b0,
        ALUOp,
        alu_result,
        alu_cout
    );

    WriteBackPath writeback_path(
        alu_result,
        rf_write_data
    );

    OutputRegister output_register(
        clk,
        alu_result,
        output_port
    );

    NumInstCounter num_inst_counter(
        clk,
        reset_n,
        num_inst
    );

endmodule

