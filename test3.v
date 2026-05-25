///////////////////////////////////////////////////////////////////////////
// MODULE: CPU for TSC microcomputer: cpu.v
// Author:
// Description: Single-cycle TSC CPU implementing ADD, ADI, LHI, JMP, WWD

`timescale 100ps / 100ps
`define WORD_SIZE 16

// ── ALU 모듈 ──────────────────────────────────────────────────────────────
module ALU(
    input [15:0] A,
    input [15:0] B,
    input Cin,
    input [3:0] OP,
    output reg Cout,
    output reg [15:0] C
    );
    
    parameter [3:0] OP_ADD  = 4'b0000,
                    OP_SUB  = 4'b0001;
    parameter [3:0] OP_ID   = 4'b0010,
                    OP_NAND = 4'b0011,
                    OP_NOR  = 4'b0100,
                    OP_XNOR = 4'b0101,
                    OP_NOT  = 4'b0110,
                    OP_AND  = 4'b0111,
                    OP_OR   = 4'b1000,
                    OP_XOR  = 4'b1001;
    parameter [3:0] OP_LRS  = 4'b1010,
                    OP_ARS  = 4'b1011,
                    OP_RR   = 4'b1100,
                    OP_LLS  = 4'b1101,
                    OP_ALS  = 4'b1110,
                    OP_RL   = 4'b1111;
                    
    reg [16:0] result;
    
    always @(*) begin 
        case(OP)
            OP_ADD: begin
                result = {1'b0, A} + {1'b0, B} + {16'b0, Cin};
                C = result[15:0]; Cout = result[16];
            end
            OP_SUB: begin
                C = A - (B + Cin);
                Cout = (A < ({1'b0, B} + Cin)) ? 1 : 0;
            end
            OP_ID:   begin Cout=0; C=A; end
            OP_NAND: begin Cout=0; C=~(A&B); end
            OP_NOR:  begin Cout=0; C=~(A|B); end
            OP_XNOR: begin Cout=0; C=~(A^B); end
            OP_NOT:  begin Cout=0; C=~A; end
            OP_AND:  begin Cout=0; C=A&B; end
            OP_OR:   begin Cout=0; C=A|B; end
            OP_XOR:  begin Cout=0; C=A^B; end
            OP_LRS:  begin Cout=0; C=A>>1; end
            OP_ARS:  begin Cout=0; C={A[15],A[15:1]}; end
            OP_RR:   begin Cout=0; C={A[0],A[15:1]}; end
            OP_LLS:  begin Cout=0; C=A<<1; end
            OP_ALS:  begin Cout=0; C=A<<<1; end
            OP_RL:   begin Cout=0; C={A[14:0],A[15]}; end
            default: begin Cout=0; C=0; end
        endcase
    end
endmodule

// ── RF 모듈 ───────────────────────────────────────────────────────────────
module RF(
    input [1:0] addr1,
    input [1:0] addr2,
    input [1:0] addr3,
    input [15:0] data3,
    input write,
    input clk,
    input reset,
    output reg [15:0] data1,
    output reg [15:0] data2
    );
    
    reg [15:0] RF [0:3];

    always @(posedge clk) begin
        if (reset == 1) begin
            RF[0] <= 0; RF[1] <= 0; RF[2] <= 0; RF[3] <= 0;
        end
        else if (write == 1)
            RF[addr3] <= data3;
    end
    
    always @(*) begin
        data1 = RF[addr1];
        data2 = RF[addr2];
    end
endmodule

// ── CPU 모듈 ──────────────────────────────────────────────────────────────
module cpu (
    output readM,
    output [`WORD_SIZE-1:0] address,
    inout  [`WORD_SIZE-1:0] data,
    input  inputReady,
    input  reset_n,
    input  clk,
    output [`WORD_SIZE-1:0] num_inst,
    output [`WORD_SIZE-1:0] output_port
);

    // ── Opcode / Function code 상수 ──────────────────────────
    parameter OP_R   = 4'd15;
    parameter OP_ADI = 4'd4;
    parameter OP_LHI = 4'd6;
    parameter OP_JMP = 4'd9;
    parameter FC_ADD = 6'd0;
    parameter FC_WWD = 6'd28;

    // ── 내부 레지스터 ─────────────────────────────────────────
    // RF 배열을 cpu 내부에서 직접 관리 (타이밍 문제 없음)
    reg [`WORD_SIZE-1:0] PC;
    reg [`WORD_SIZE-1:0] RF [0:3];   // 레지스터 파일
    reg [`WORD_SIZE-1:0] num_inst_reg;
    reg [`WORD_SIZE-1:0] output_port_reg;
    reg readM_reg;
    reg [`WORD_SIZE-1:0] instruction;

    // ── 출력 연결 ─────────────────────────────────────────────
    assign readM       = readM_reg;
    assign address     = PC;
    assign data        = 16'bz;
    assign num_inst    = num_inst_reg;
    assign output_port = output_port_reg;

    // ── Reset + Fetch 시작 (posedge clk) ─────────────────────
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            PC              <= 16'd0;
            readM_reg       <= 1'b0;
            num_inst_reg    <= 16'd0;
            output_port_reg <= 16'd0;
            RF[0] <= 16'd0;
            RF[1] <= 16'd0;
            RF[2] <= 16'd0;
            RF[3] <= 16'd0;
        end
        else begin
            readM_reg <= 1'b1;   // 다음 명령어 fetch 시작
        end
    end

    // ── 명령어 수신 및 실행 (posedge inputReady) ─────────────
    always @(posedge inputReady or negedge reset_n) begin
        if (!reset_n) begin
            // reset은 위의 always 블록에서 처리
        end
        else begin
            instruction  <= data;
            readM_reg    <= 1'b0;
            num_inst_reg <= num_inst_reg + 16'd1;

            case (data[15:12])

                OP_R: begin
                    case (data[5:0])
                        FC_ADD: begin
                            // ALU: RF[rs] + RF[rt] → RF[rd]
                            RF[data[7:6]] <= RF[data[11:10]] + RF[data[9:8]];
                            PC <= PC + 16'd1;
                        end
                        FC_WWD: begin
                            output_port_reg <= RF[data[11:10]];
                            PC <= PC + 16'd1;
                        end
                        default: PC <= PC + 16'd1;
                    endcase
                end

                OP_ADI: begin
                    // ALU: RF[rs] + sign_ext(imm) → RF[rt]
                    RF[data[9:8]] <= RF[data[11:10]] + {{8{data[7]}}, data[7:0]};
                    PC <= PC + 16'd1;
                end

                OP_LHI: begin
                    RF[data[9:8]] <= {data[7:0], 8'b0};
                    PC <= PC + 16'd1;
                end

                OP_JMP: begin
                    PC <= {PC[15:12], data[11:0]};
                end

                default: PC <= PC + 16'd1;

            endcase
        end
    end

endmodule