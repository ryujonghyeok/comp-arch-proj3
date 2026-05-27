// Diagram block: Data MEM
//
// cpu_github.v does not implement Data MEM.
//
// The opcode list defines LWD and SWD:
//
//   `define OPCODE_LWD 4'd7
//   `define OPCODE_SWD 4'd8
//
// But the Control module never handles those opcodes, and the Datapath has
// no data-memory address/data-in/data-out path. Therefore there is no real
// Data MEM block to extract from cpu_github.v.

