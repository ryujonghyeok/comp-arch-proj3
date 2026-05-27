`include "cpu_github_modules/cpu_defs.vh"

// Diagram block: Inst. MEM interface
//
// cpu_github.v does not include instruction memory inside the CPU.
// Instead, it exposes these signals to the testbench:
//
//   readM       CPU asks memory to read.
//   address     CPU sends PC to memory.
//   data        memory returns instruction on this bus.
//   inputReady  memory tells CPU data is ready.
//
// This module is an educational extraction of that fetch-handshake logic.
module InstructionMemoryInterface(
    input clk,
    input reset_n,
    input inputReady,
    input [`WORD_SIZE - 1:0] data,
    input [`WORD_SIZE - 1:0] instruction_addr,
    output readM,
    output [`WORD_SIZE - 1:0] address,
    output reg [`WORD_SIZE - 1:0] instruction
);

    reg [63:0] counter;
    reg [63:0] fetched_cycle;
    reg readM_sync;
    wire fetch_completed;

    assign address = instruction_addr;
    assign fetch_completed = (counter == fetched_cycle);
    assign readM = fetch_completed ? 0 : readM_sync;

    always @(posedge clk) begin
        if(reset_n == 1'b0) begin
            counter <= 63'b0;
            readM_sync <= 0;
        end
        else begin
            counter <= counter + 1;
            readM_sync <= 1;
        end
    end

    always @(posedge inputReady or negedge reset_n) begin
        if(reset_n == 1'b0) begin
            fetched_cycle <= -1;
        end
        else begin
            instruction <= data;
            fetched_cycle <= counter;
        end
    end

endmodule

