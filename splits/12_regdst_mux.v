`include "cpu_github_modules/cpu_defs.vh"

// Selects the register-file write address.
module RegDstMux(
    input RegDst,
    input [`reg_addr_length - 1:0] rt,
    input [`reg_addr_length - 1:0] rd,
    output [`reg_addr_length - 1:0] write_addr
);

    assign write_addr = RegDst ? rd : rt;

endmodule

