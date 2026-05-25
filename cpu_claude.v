///////////////////////////////////////////////////////////////////////////
// MODULE: CPU for TSC microcomputer: cpu.v
// Author:
// Description: Single-cycle TSC CPU implementing ADD, ADI, LHI, JMP, WWD

// DEFINITIONS
`define WORD_SIZE 16    // data and address word size

// MODULE DECLARATION
module cpu (
    output readM,                       // read from memory
    output [`WORD_SIZE-1:0] address,    // current address for data
    inout  [`WORD_SIZE-1:0] data,       // data being input or output
    input  inputReady,                  // indicates that data is ready from the input port
    input  reset_n,                     // active-low RESET signal
    input  clk,                         // clock signal

    // for debuging/testing purpose
    output [`WORD_SIZE-1:0] num_inst,   // number of instruction during execution
    output [`WORD_SIZE-1:0] output_port // this will be used for a "WWD" instruction
);

    // ── Opcode / Function code 상수 ──────────────────────────
    parameter OP_R   = 4'd15;   // R-format (ADD, WWD 등)
    parameter OP_ADI = 4'd4;
    parameter OP_LHI = 4'd6;
    parameter OP_JMP = 4'd9;

    parameter FC_ADD = 6'd0;
    parameter FC_WWD = 6'd28;

    // ── 내부 레지스터 ────────────────────────────────────────
    reg [`WORD_SIZE-1:0] PC;
    reg [`WORD_SIZE-1:0] RF [0:3];      // 레지스터 파일 $0~$3

    reg [`WORD_SIZE-1:0] num_inst_reg;
    reg [`WORD_SIZE-1:0] output_port_reg;

    reg readM_reg;                       // readM 제어 레지스터
    reg [`WORD_SIZE-1:0] instruction;    // 현재 실행 중인 명령어

    // ── 출력 연결 ─────────────────────────────────────────────
    assign readM       = readM_reg;
    assign address     = PC;
    assign data        = 16'bz;          // CPU는 메모리 읽기만 함
    assign num_inst    = num_inst_reg;
    assign output_port = output_port_reg;

    // ── 명령어 필드 디코딩 (combinational) ───────────────────
    wire [3:0] opcode = instruction[15:12];
    wire [1:0] rs     = instruction[11:10];
    wire [1:0] rt     = instruction[9:8];
    wire [1:0] rd     = instruction[7:6];
    wire [5:0] func   = instruction[5:0];
    wire [7:0] imm8   = instruction[7:0];
    wire [11:0] tgt   = instruction[11:0];

    // 8비트 부호 확장
    wire [`WORD_SIZE-1:0] imm_se = {{8{imm8[7]}}, imm8};

    // ── Reset + Fetch 시작 (posedge clk) ─────────────────────
    // reset 해제 후 첫 클럭에 readM=1로 fetch 시작
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
            // 명령어 실행이 끝난 직후(또는 reset 해제 직후)
            // readM=1로 세팅하여 다음 명령어 fetch 시작
            readM_reg <= 1'b1;
        end
    end

    // ── 명령어 수신 및 실행 (posedge inputReady) ─────────────
    // inputReady=1이 되는 순간(클럭 중간) 명령어를 받아 처리
    // posedge clk보다 앞서 레지스터 값이 업데이트되므로
    // 다음 posedge clk에서 테스트벤치가 올바른 값을 샘플링함
    always @(posedge inputReady or negedge reset_n) begin
        if (!reset_n) begin
            // reset은 위의 always 블록에서 처리
        end
        else begin
            // 1) 메모리에서 받은 명령어 래치
            instruction <= data;

            // 2) readM 해제 (데이터 수신 완료)
            readM_reg <= 1'b0;

            // 3) 명령어 실행
            // - num_inst 증가
            // - RF / output_port 업데이트
            // - PC 업데이트
            num_inst_reg <= num_inst_reg + 16'd1;

            case (data[15:12])   // opcode (data를 직접 사용, instruction 래치 전)

                OP_R: begin
                    case (data[5:0])   // function code
                        FC_ADD: begin
                            RF[data[7:6]] <= RF[data[11:10]] + RF[data[9:8]];
                            PC <= PC + 16'd1;
                        end
                        FC_WWD: begin
                            output_port_reg <= RF[data[11:10]];
                            PC <= PC + 16'd1;
                        end
                        default: begin
                            PC <= PC + 16'd1;
                        end
                    endcase
                end

                OP_ADI: begin
                    // ADI $rt, $rs, imm  :  $rt = $rs + sign_ext(imm)
                    RF[data[9:8]] <= RF[data[11:10]] + {{8{data[7]}}, data[7:0]};
                    PC <= PC + 16'd1;
                end

                OP_LHI: begin
                    // LHI $rt, imm  :  $rt = imm << 8
                    RF[data[9:8]] <= {data[7:0], 8'b0};
                    PC <= PC + 16'd1;
                end

                OP_JMP: begin
                    // JMP target  :  PC = PC[15:12] ## target[11:0]
                    PC <= {PC[15:12], data[11:0]};
                end

                default: begin
                    PC <= PC + 16'd1;
                end

            endcase
        end
    end

endmodule