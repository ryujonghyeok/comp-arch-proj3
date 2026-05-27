module RF(
    input clk,
    input reset_n,
    input [1:0] addr1,
    output reg [15:0] data1,
    input [1:0] addr2,
    output reg [15:0] data2,
    input write,
    input [1:0] addr3,
    input [15:0] data3
);

    reg [15:0] regs [0:3];

    always @(posedge clk) begin
        if (!reset_n) begin
            regs[0] <= 16'h0000;
            regs[1] <= 16'h0000;
            regs[2] <= 16'h0000;
            regs[3] <= 16'h0000;
        end
        else if (write) begin
            regs[addr3] <= data3;
        end
    end

    always @(*) begin
        data1 = regs[addr1];
        data2 = regs[addr2];
    end

endmodule