///////////////////////////////////////////////////////////////////////////
// MODULE: CPU for TSC microcomputer: cpu.v
// Author: gangtaeng_parangvo@snu.ac.kr
// Description: Self-contained SingleCycleCPU design.
///////////////////////////////////////////////////////////////////////////

`ifndef TSC_CPU_OPCODES_V
`define TSC_CPU_OPCODES_V

`define WORD_SIZE 16

// TSC ISA Instruction Function Code
`define FUNC_ADD 6'd0
`define FUNC_SUB 6'd1
`define FUNC_AND 6'd2
`define FUNC_ORR 6'd3
`define FUNC_NOT 6'd4
`define FUNC_TCP 6'd5
`define FUNC_SHL 6'd6
`define FUNC_SHR 6'd7
`define FUNC_WWD 6'd28

// TSC ISA Instruction Opcodes
`define OPCODE_ADI 4'd4
`define OPCODE_ORI 4'd5
`define OPCODE_LHI 4'd6
`define OPCODE_LWD 4'd7
`define OPCODE_SWD 4'd8
`define OPCODE_BNE 4'd0
`define OPCODE_BEQ 4'd1
`define OPCODE_BGZ 4'd2
`define OPCODE_BLZ 4'd3
`define OPCODE_JMP 4'd9
`define OPCODE_JAL 4'd10
`define OPCODE_Rtype 4'd15

// Bit-Length for each instruction format type
`define opcode_length 4
`define reg_addr_length 2
`define func_code_length 6
`define Immediate_length 8
`define Jump_target_length 12

// Index for parsing instruction (by TSC ISA Instruction Format)
`define opcode_left (`WORD_SIZE - 1)
`define opcode_right (`WORD_SIZE - `opcode_length)
`define rs_left (`opcode_right - 1)
`define rs_right (`opcode_right - `reg_addr_length)
`define rt_left (`rs_right - 1)
`define rt_right (`rs_right - `reg_addr_length)
`define rd_left (`rt_right - 1)
`define rd_right (`rt_right - `reg_addr_length)
`define func_code_left (`func_code_length - 1)
`define func_code_right (0)
`define immediate_left (`Immediate_length - 1)
`define immediate_right (0)
`define target_left (`Jump_target_length - 1)
`define target_right (0)

// ALU OPCODES
// Arithmetic
`define OP_ADD 4'b0000
`define OP_SUB 4'b0001
// Bitwise Boolean operation
`define OP_ID 4'b0010
`define OP_NAND 4'b0011
`define OP_NOR 4'b0100
`define OP_XNOR 4'b0101
`define OP_NOT 4'b0110
`define OP_AND 4'b0111
`define OP_OR 4'b1000
`define OP_XOR 4'b1001
// Shifting
`define OP_LRS 4'b1010
`define OP_ARS 4'b1011
`define OP_RR 4'b1100
`define OP_LHI 4'b1101
`define OP_ALS 4'b1110
`define OP_RL 4'b1111

`endif

`ifndef NUM_REG
`define NUM_REG (1<<`reg_addr_length)
`endif

// MODULE DECLARATION
module cpu (

    output readM,                           // read from memory
    output [`WORD_SIZE - 1:0] address,      // current address for data

    inout [`WORD_SIZE - 1:0] data,          // data being input or output
    input inputReady,                       // indicates that data is ready from the input port
    input reset_n,                          // active-low RESET signal
    input clk,                              // clock signal

    // for debuging/testing purpose
    output [`WORD_SIZE - 1:0] num_inst,     // number of instruction during execution
    output [`WORD_SIZE - 1:0] output_port   // this will be used for a "WWD" instruction
);

    reg [`WORD_SIZE - 1 : 0] num_instruction;

    // instruction fetch
    wire [`WORD_SIZE - 1 : 0] instruction_addr; // address of instruction to read(Program Counter)
    reg [`WORD_SIZE - 1 : 0] instruction;       // fetched Instruction
    reg [63:0] counter;         // counter for clk cycle
    reg [63:0] fetched_cycle;   // save counter at which current instruction was fetched
    wire fetch_completed;       // if instruction was fetched this cycle
    reg readM_sync;             // request from cpu for new instruction(synced with clk)

    // parsed instruction
    wire [`opcode_length - 1 : 0] opcode;
    wire [`func_code_length - 1 : 0] func_code;
    wire [`Immediate_length - 1 : 0] I_immediate;
    wire [`Jump_target_length - 1 : 0] J_target;
    // parse instruction
    assign opcode = instruction[`opcode_left : `opcode_right];
    assign func_code = instruction[`func_code_left : `func_code_right];
    assign I_immediate = { {8{instruction[`immediate_left]}}, instruction[`immediate_left : `immediate_right]}; //Sign-extend
    assign J_target = instruction[`target_left : `target_right];

    // port : control_unit -> PC
    wire Jump;

    // ports : Control -> DP
    wire RegDst, ALUSrc, RegWrite, isWWD;
    wire [3:0] ALUOp;

    // DP module ports
    wire [`WORD_SIZE - 1 : 0] output_data;

    // output signals
    reg [`WORD_SIZE - 1 : 0] output_save; // save output_data from DP
    always @(posedge clk) begin
        output_save = output_data;
    end
    assign output_port = output_save; // only used for WWD
    assign address = instruction_addr; // PC to memory
    assign num_inst = num_instruction;

    // check if fetch was completed on this cycle
    // if already fetched -> readM = 0
    assign fetch_completed = (counter == fetched_cycle);
    assign readM = fetch_completed ? 0 : readM_sync;

    always @(posedge clk) begin
        if(reset_n == 1'b0) begin // reset
            num_instruction <= 0;
            counter <= 63'b0;
            readM_sync <= 0;
        end
        else begin
            num_instruction <= num_instruction + 1;
            counter <= counter + 1; // increment cycle counter
            readM_sync <= 1; // request new instruction
        end
    end

    //if inputReady goes high -> "fetch" (receive new instruction from memory)
    always @(posedge inputReady or negedge reset_n) begin
        if(reset_n == 1'b0) begin // reset
            fetched_cycle <= -1;
        end
        else begin
            instruction <= data; // fetch
            fetched_cycle <= counter; // remember that cpu fetched this cycle
        end
    end

    // ProgramCounter module
    PC PC_UUT(
        clk,
        reset_n,
        Jump,
        J_target,
        instruction_addr
    );

    // Control module
    Control Control_UUT (
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

    // Datapath module
    DP DP_UUT (
        clk,
        reset_n,
        output_data,
        RegDst,
        RegWrite,
        ALUSrc,
        ALUOp,
        Jump,
        isWWD,
        instruction
    );

endmodule

module PC(
    input clk,
    input reset_n,

    input Jump, // indicate if current instruction is Jump
    input [`Jump_target_length - 1 : 0] J_target,

    output reg [`WORD_SIZE - 1 : 0] instruction_addr // memory address for next instruction
);

    always @(posedge clk) begin
        if(reset_n == 1'b0) begin // if reset_n is low -> reset
            instruction_addr <= 0;
        end
        else if(Jump) begin // if current instruction is Jump -> make next addr by concat
            instruction_addr <= {instruction_addr[`WORD_SIZE - 1 : `WORD_SIZE - 4], J_target};
        end
        else begin // next addr
            instruction_addr <= instruction_addr + `WORD_SIZE'b1;
        end
    end

endmodule

module Control(
    input reset_n,
    input [`opcode_length-1:0] opcode,
    input [`func_code_length-1:0] func_code,

    output reg RegDst,
    output reg Jump,
    output reg [3:0] ALUOperation,
    output reg ALUSrc,
    output reg RegWrite,
    output reg isWWD
);

    always @(*) begin
        case(opcode)
            `OPCODE_Rtype : begin // R-type instruction
                RegDst = 1'b1;
                Jump = 1'b0;
                ALUSrc = 1'b0;
                RegWrite = 1'b1;
                case(func_code)
                    `FUNC_ADD : begin
                        ALUOperation = `OP_ADD;
                        isWWD = 1'b0;
                    end
                    `FUNC_WWD : begin
                        ALUOperation = `OP_ID;
                        RegWrite = 1'b0;
                        isWWD = 1'b1;
                    end
                endcase
            end
            `OPCODE_ADI : begin // ADI instruction
                RegDst = 1'b0;
                Jump = 1'b0;
                ALUOperation =  `OP_ADD;
                ALUSrc = 1'b1;
                RegWrite = 1'b1;
                isWWD = 1'b0;
            end
            `OPCODE_LHI : begin // LHI instruction
                RegDst = 1'b0;
                Jump = 1'b0;
                ALUOperation = `OP_LHI;
                ALUSrc = 1'b1;
                RegWrite = 1'b1;
                isWWD = 1'b0;
            end
            `OPCODE_JMP : begin // JMP instruction
                RegDst = 1'b0;
                Jump = 1'b1;
                ALUOperation = `OP_ADD;
                ALUSrc = 1'b0;
                RegWrite = 1'b0;
                isWWD = 1'b0;
            end
        endcase
    end
endmodule

module DP(
    input clk,
    input reset_n,

    output [`WORD_SIZE - 1 : 0] output_data,

    // input from Control
    input RegDst,
    input RegWrite,
    input ALUSrc,
    input [3:0] ALUOp,
    input Jump,
    input isWWD,

    input [`WORD_SIZE - 1 : 0] instruction
);
    // parsed instructions
    wire [`opcode_length - 1:0] opcode;
    wire [`reg_addr_length - 1 : 0] rs, rt, rd;
    wire [`WORD_SIZE - 1 : 0] I_immediate;
    wire [`Jump_target_length - 1 : 0] J_target;
    wire [`func_code_length - 1 : 0] func_code;

    // RegisterFile module ports
    wire [`reg_addr_length - 1 : 0] write_addr;
    wire [`WORD_SIZE - 1 : 0] RF_rs;
    wire [`WORD_SIZE - 1 : 0] RF_rd;
    wire [`WORD_SIZE - 1 : 0] RF_rt;
    wire [`WORD_SIZE - 1 : 0] RF_write;

    // ALU module ports
    wire [`WORD_SIZE - 1 : 0] ALU_B;
    wire [`WORD_SIZE - 1 : 0] ALU_C;
    wire ALU_Cout;

    // parse instruction
    assign opcode = instruction[`opcode_left : `opcode_right];
    assign func_code = instruction[`func_code_left : `func_code_right];
    assign rs = instruction[`rs_left : `rs_right];
    assign rt = instruction[`rt_left : `rt_right];
    assign rd = instruction[`rd_left : `rd_right];
    assign I_immediate = { {8{instruction[`immediate_left]}}, instruction[`immediate_left : `immediate_right]}; //Sign-extend
    assign J_target = instruction[`target_left : `target_right];

    // mux selection by control signal
    assign write_addr = (RegDst) ? rd : rt;
    assign ALU_B = (ALUSrc) ? I_immediate : RF_rt;
    assign RF_write = ALU_C;

    // output data
    assign output_data = ALU_C;

    // RegisterFile module
    RF RF_UUT(
        clk,
        reset_n,
        rs,
        RF_rs,
        rt,
        RF_rt,
        RegWrite,
        write_addr,
        RF_write
    );

    // ALU module
    ALU ALU_UUT(
        RF_rs,
        ALU_B,
        1'b0,
        ALUOp,
        ALU_C,
        ALU_Cout
    );
endmodule

module RF(
    input clk,
    input reset_n,

    input [`reg_addr_length-1 : 0] addr1,
    output reg [`WORD_SIZE-1 : 0] data1,

    input [`reg_addr_length-1 : 0] addr2,
    output reg [`WORD_SIZE-1 : 0] data2,

    input write,
    input [`reg_addr_length-1 : 0] addr3,
    input [`WORD_SIZE-1 : 0] data3
);

    reg [`WORD_SIZE-1 : 0] memory[`NUM_REG-1 : 0];

    always @(*) begin
        data1 = memory[addr1];
        data2 = memory[addr2];
    end

    integer addr_idx;
    always @(negedge reset_n or posedge clk) begin

        if(reset_n == 1'b0) begin
            for(addr_idx = 0; addr_idx < `NUM_REG; addr_idx = addr_idx + 1) begin
                memory[addr_idx] <= `WORD_SIZE'b0;
            end
        end

        else begin
            if(write) begin
                memory[addr3] <= data3;
            end
        end
    end
endmodule

module ALU(
    input [15:0] A,
    input [15:0] B,
    input Cin,

    input [3:0] OP,

    output reg [15:0] C,
    output reg Cout
);
    //Combinational logic
    always @(*) begin
        case(OP)
            `OP_ADD :    {Cout, C} = {1'b0, A[15:0]} + {1'b0, B[15:0]} + Cin;
            `OP_SUB :    {Cout, C} = {1'b0, A[15:0]} - {1'b0, B[15:0]} - Cin;
            `OP_ID :     {Cout, C} = {1'b0, A};
            `OP_NAND :   {Cout, C} = {1'b0, ~(A&B)};
            `OP_NOR :    {Cout, C} = {1'b0, ~(A|B)};
            `OP_XNOR :   {Cout, C} = {1'b0, ~(A^B)};
            `OP_NOT :    {Cout, C} = {1'b0, ~A};
            `OP_AND :    {Cout, C} = {1'b0, (A&B)};
            `OP_OR :     {Cout, C} = {1'b0, (A|B)};
            `OP_XOR :    {Cout, C} = {1'b0, (A^B)};
            `OP_LRS :    {Cout, C} = {1'b0, 1'b0, A[15:1]};
            `OP_ARS :    {Cout, C} = {1'b0, A[15], A[15:1]};
            `OP_RR :     {Cout, C} = {1'b0, A[0], A[15:1]};
            `OP_LHI :    {Cout, C} = {1'b0, B[7:0], 8'b00000000};
            `OP_ALS :    {Cout, C} = {1'b0, A[14:0], 1'b0};
            `OP_RL :     {Cout, C} = {1'b0, A[14:0], A[15]};
            default :    {Cout, C} = {17'b00000000000000000};
        endcase
    end
endmodule
//////////////////////////////////////////////////////////////////////////
