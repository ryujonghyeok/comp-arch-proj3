`include "cpu_github_modules/cpu_defs.vh"

// Diagram block: PC
//
// In the diagram, PC sends an address to instruction memory.
// In cpu_github.v, this address is called instruction_addr.
module PC(
    input clk,
    input reset_n,
    input Jump,
    input [`Jump_target_length - 1 : 0] J_target,
    output reg [`WORD_SIZE - 1 : 0] instruction_addr
);

    always @(posedge clk) begin
        if(reset_n == 1'b0) begin
            instruction_addr <= 0;
        end
        else if(Jump) begin
            instruction_addr <= {instruction_addr[`WORD_SIZE - 1 : `WORD_SIZE - 4], J_target};
        end
        else begin
            // This CPU uses word addresses, so the next instruction is +1.
            // The diagram shows +4 because many byte-addressed CPUs use PC+4.
            instruction_addr <= instruction_addr + `WORD_SIZE'b1;
        end
    end

endmodule

