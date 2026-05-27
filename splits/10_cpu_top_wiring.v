`include "cpu_github_modules/cpu_defs.vh"

// Diagram block: CPU top wiring
//
// This file shows how the diagram blocks connect together.
// It is an educational split of cpu_github.v, not a drop-in replacement for
// the original CPU file.
//
// Diagram flow:
//
//   PC
//    -> instruction memory interface
//    -> instruction fields
//    -> control unit
//    -> register file
//    -> sign extend / ALU operand mux
//    -> ALU
//    -> writeback path
//    -> register file
//
module CPU_Top_Wiring(
    output readM,
    output [`WORD_SIZE - 1:0] address,
    inout [`WORD_SIZE - 1:0] data,
    input inputReady,
    input reset_n,
    input clk,
    output [`WORD_SIZE - 1:0] num_inst,
    output [`WORD_SIZE - 1:0] output_port
);

    // Instruction counter, same role as cpu_github.v num_instruction.
    reg [`WORD_SIZE - 1:0] num_instruction;

    always @(posedge clk) begin
        if (reset_n == 1'b0) begin
            num_instruction <= 0;
        end
        else begin
            num_instruction <= num_instruction + 1;
        end
    end

    assign num_inst = num_instruction;

    // PC / instruction fetch wires.
    wire [`WORD_SIZE - 1:0] instruction_addr;
    wire [`WORD_SIZE - 1:0] instruction;

    // Instruction field wires.
    wire [`opcode_length - 1:0] opcode;
    wire [`func_code_length - 1:0] func_code;
    wire [`reg_addr_length - 1:0] rs;
    wire [`reg_addr_length - 1:0] rt;
    wire [`reg_addr_length - 1:0] rd;
    wire [7:0] imm8;
    wire [`WORD_SIZE - 1:0] imm16;
    wire [`Jump_target_length - 1:0] J_target;

    assign opcode = instruction[`opcode_left : `opcode_right];
    assign func_code = instruction[`func_code_left : `func_code_right];
    assign rs = instruction[`rs_left : `rs_right];
    assign rt = instruction[`rt_left : `rt_right];
    assign rd = instruction[`rd_left : `rd_right];
    assign imm8 = instruction[`immediate_left : `immediate_right];
    assign J_target = instruction[`target_left : `target_right];

    // Control wires.
    wire RegDst;
    wire Jump;
    wire ALUSrc;
    wire RegWrite;
    wire isWWD;
    wire [3:0] ALUOp;

    // Register file wires.
    wire [`reg_addr_length - 1:0] write_addr;
    wire [`WORD_SIZE - 1:0] rf_data_a;
    wire [`WORD_SIZE - 1:0] rf_data_b;
    wire [`WORD_SIZE - 1:0] rf_write_data;

    assign write_addr = RegDst ? rd : rt;

    // ALU wires.
    wire [`WORD_SIZE - 1:0] alu_b;
    wire [`WORD_SIZE - 1:0] alu_result;
    wire alu_cout;

    // WWD/debug output path.
    reg [`WORD_SIZE - 1:0] output_save;

    always @(posedge clk) begin
        output_save = alu_result;
    end

    assign output_port = output_save;

    // PC block from the diagram.
    PC pc_block(
        clk,
        reset_n,
        Jump,
        J_target,
        instruction_addr
    );

    // Inst. MEM interface block.
    //
    // This is not a real memory. It is the handshake to external memory, which
    // the testbench provides.
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

    // CU block.
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

    // RF block.
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

    // SE block.
    SignExtend8To16 sign_extend(
        imm8,
        imm16
    );

    // MB mux block.
    ALUOperandMux alu_operand_mux(
        ALUSrc,
        rf_data_b,
        imm16,
        alu_b
    );

    // ALU block.
    ALU alu_block(
        rf_data_a,
        alu_b,
        1'b0,
        ALUOp,
        alu_result,
        alu_cout
    );

    // Simplified MD/writeback block.
    //
    // The original cpu_github.v does not implement Data MEM, so writeback is
    // always the ALU result.
    WriteBackPath writeback_path(
        alu_result,
        rf_write_data
    );

endmodule
