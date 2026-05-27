# Diagram-Based Split of cpu_github.v

This folder splits the CPU by the blocks shown in the datapath diagram, not by
the original Verilog module boundaries.

Important difference:

- The diagram shows `Inst. MEM` and `Data MEM` as CPU-adjacent blocks.
- `cpu_github.v` does not contain real instruction memory or data memory.
- `cpu_tb.v` / `cpu_tb_1000.v` model memory outside the CPU through
  `readM`, `address`, `data`, and `inputReady`.

Mapping:

| Diagram block | Split file | Exists inside original cpu_github.v? |
| --- | --- | --- |
| PC | `01_pc.v` | Yes, module `PC` |
| Inst. MEM interface | `02_instruction_memory_interface.v` | Partly, in top `cpu` |
| CU | `03_control_unit.v` | Yes, module `Control` |
| RF | `04_register_file.v` | Yes, module `RF` |
| SE | `05_sign_extend.v` | Inline expression in `cpu` and `DP` |
| MB mux | `06_alu_operand_mux.v` | Inline expression in `DP` |
| ALU | `07_alu.v` | Yes, module `ALU` |
| Data MEM | `08_data_memory_note.v` | No, not implemented |
| MD mux / writeback | `09_writeback_path.v` | Simplified to ALU result only |
| CPU top wiring | `10_cpu_top_shape.v` | Based on top `cpu` |

