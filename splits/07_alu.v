`include "cpu_github_modules/cpu_defs.vh"

// Diagram block: ALU
module ALU(
    input [15:0] A,
    input [15:0] B,
    input Cin,
    input [3:0] OP,
    output reg [15:0] C,
    output reg Cout
);

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

