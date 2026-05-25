///////////////////////////////////////////////////////////////////////////
// MODULE: CPU for TSC microcomputer: rjh.v
// Description: Single-cycle CPU for the provided Project 3 testbench.

// DEFINITIONS
`define WORD_SIZE 16

// MODULE DECLARATION
module cpu (
    output readM,
    output [`WORD_SIZE-1:0] address,
    inout  [`WORD_SIZE-1:0] data,
    input  inputReady,
    input  reset_n,
    input  clk,

    // for debugging/testing purpose
    output [`WORD_SIZE-1:0] num_inst,
    output [`WORD_SIZE-1:0] output_port
);

    parameter OP_ADI = 4'h4;
    parameter OP_LHI = 4'h6;
    parameter OP_JMP = 4'h9;
    parameter OP_R   = 4'hf;

    parameter FUNC_ADD = 6'h00;
    parameter FUNC_WWD = 6'h1c;

    reg [`WORD_SIZE-1:0] pc;
    reg [`WORD_SIZE-1:0] reg_file [0:3];
    reg [`WORD_SIZE-1:0] num_inst_reg;
    reg [`WORD_SIZE-1:0] output_port_reg;
    reg readM_reg;

    assign readM = readM_reg;
    assign address = pc;
    assign data = `WORD_SIZE'bz;
    assign num_inst = num_inst_reg;
    assign output_port = output_port_reg;

    always @(posedge clk or posedge inputReady or negedge reset_n) begin
        if (!reset_n) begin
            pc <= 16'd0;
            readM_reg <= 1'b0;
            num_inst_reg <= 16'd0;
            output_port_reg <= 16'd0;
            reg_file[0] <= 16'd0;
            reg_file[1] <= 16'd0;
            reg_file[2] <= 16'd0;
            reg_file[3] <= 16'd0;
        end else if (inputReady) begin
            readM_reg <= 1'b0;
            num_inst_reg <= num_inst_reg + 16'd1;

            case (data[15:12])
                OP_R: begin
                    case (data[5:0])
                        FUNC_ADD: begin
                            reg_file[data[7:6]] <= reg_file[data[11:10]] + reg_file[data[9:8]];
                            pc <= pc + 16'd1;
                        end
                        FUNC_WWD: begin
                            output_port_reg <= reg_file[data[11:10]];
                            pc <= pc + 16'd1;
                        end
                        default: begin
                            pc <= pc + 16'd1;
                        end
                    endcase
                end

                OP_ADI: begin
                    reg_file[data[9:8]] <= reg_file[data[11:10]] + {{8{data[7]}}, data[7:0]};
                    pc <= pc + 16'd1;
                end

                OP_LHI: begin
                    reg_file[data[9:8]] <= {data[7:0], 8'b0};
                    pc <= pc + 16'd1;
                end

                OP_JMP: begin
                    pc <= {pc[15:12], data[11:0]};
                end

                default: begin
                    pc <= pc + 16'd1;
                end
            endcase
        end else begin
            readM_reg <= 1'b1;
        end
    end

endmodule
