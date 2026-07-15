# riscv-single-cycle

[![CI](https://github.com/drewbabel/riscv-single-cycle/actions/workflows/ci.yml/badge.svg)](https://github.com/drewbabel/riscv-single-cycle/actions/workflows/ci.yml)

A configurable single-cycle RV32I processor with machine-mode traps, written in SystemVerilog.

The core executes the RV32I base integer instruction set at one instruction per clock, extended with the Zicsr control registers, machine-mode traps, and a core-local timer. The program counter addresses instruction memory, the `control_unit` decodes the fetched word combinationally, the register file supplies operands, the `alu` computes, and the ALU result, a loaded word, a CSR value, or the return address writes back within the cycle. The only sequential state is the `pc` register, the register file, data memory, the CSR file, and the timer.

Data memory is organized as 32-bit words and supports byte, halfword, and word accesses through per-byte write strobes and a load-extend stage. `control_decoder` maps each opcode to the datapath control lines, `alu_decoder` derives the ALU operation from `funct3` and `funct7`, `extend` builds the I, S, B, U, and J immediates, and the `datapath` holds the ALU-operand, write-back, and next-PC multiplexers that the control lines steer.

The `csr` block holds the machine-mode registers and the trap unit. On an exception or an enabled timer interrupt, the trap unit records the faulting program counter in `mepc` and the reason in `mcause`, then redirects the next-PC multiplexer to the `mtvec` handler ahead of any branch or sequential fetch. An `mret` restores the interrupt-enable stack and returns to `mepc`. The `clint` block raises the timer interrupt once its memory-mapped `mtime` reaches `mtimecmp`.

The design, testbenches, formal proofs, and co-simulation harness were written from scratch. A riscv-formal proof under SymbiYosys checks the assembled core against the RISC-V specification, including the machine-mode traps and the Zicsr path, and Spike lockstep co-simulation confirms every retired instruction matches a reference simulator.

![Single-cycle datapath block diagram](docs/datapath_block.svg)

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `XLEN` | `32` | Data and register width |
| `DEPTH` | `64` | Instruction and data memory depth in words |

## Interface

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| `clk` | in | 1 | System clock |
| `rst_n` | in | 1 | Synchronous active-low reset |
| `timer_irq` | in | 1 | CLINT machine-timer interrupt |
| `pc` | out | `XLEN` | Program counter of the fetched instruction |
| `alu_result` | out | `XLEN` | ALU output, also the data memory address |
| `write_data` | out | `XLEN` | Store data driven to data memory |
| `mem_write` | out | 1 | Data memory write strobe |

## Instructions

| Format | Instructions |
|--------|--------------|
| Register (`OP`) | `add` `sub` `sll` `slt` `sltu` `xor` `srl` `sra` `or` `and` |
| Immediate (`OP-IMM`) | `addi` `slti` `sltiu` `xori` `ori` `andi` `slli` `srli` `srai` |
| Load (`LOAD`) | `lb` `lbu` `lh` `lhu` `lw` |
| Store (`STORE`) | `sb` `sh` `sw` |
| Branch (`BRANCH`) | `beq` `bne` `blt` `bge` `bltu` `bgeu` |
| Jump | `jal` `jalr` |
| Upper immediate | `lui` `auipc` |
| System | `ecall` `ebreak` `mret` |
| Zicsr | `csrrw` `csrrs` `csrrc` `csrrwi` `csrrsi` `csrrci` |

The `FENCE` instruction is a no-op, and the core runs entirely in machine mode.

## Machine mode

The core traps illegal instructions, `ecall`, `ebreak`, and misaligned instruction, load, and store addresses, and takes the CLINT timer interrupt when `mstatus` and `mie` enable it.

| CSR | Purpose |
|-----|---------|
| `mstatus` | Current and prior interrupt-enable bits |
| `mtvec` | Trap handler base address |
| `mepc` | Faulting program counter |
| `mcause` | Trap cause code |
| `mtval` | Faulting address or value |
| `mie` + `mip` | Interrupt enable and pending |
| `mscratch` | Handler scratch word |
| `mcycle` + `minstret` | 64-bit cycle and retired-instruction counters |

## Verification

The riscv-formal proof wraps `riscv_single` in the RISC-V Formal Interface and checks every retired instruction against the RISC-V specification under SymbiYosys, including the machine-mode traps, the Zicsr read and write path, and the misaligned instruction, load, and store cases. Run the proof with `bash formal/rvfi/run.sh`.

Spike lockstep co-simulation runs the core against the Spike reference simulator and compares the register and memory write of every retired instruction, across hand-written programs and a randomized generator that exercises byte, halfword, and word accesses.

The `alu` carries an exhaustive SymbiYosys proof that its `result`, `zero`, `lt`, and `ltu` match an independent reference model over the full input space, and every module has a self-checking testbench, with the `csr`, `clint`, and timer paths driven through directed trap sequences.

## Results

![Arithmetic program waveform](docs/program_waveform.svg)

![Branch loop waveform](docs/loop_waveform.svg)

A timer interrupt fires once `mtime` reaches `mtimecmp`, redirecting the core to the `mtvec` handler and returning through `mret`.

![Machine timer trap waveform](docs/trap_waveform.svg)

## Building and running

Every module builds from the top-level Makefile.

```
make MOD=alu                   # run a module's testbench
make wave MOD=alu              # run the testbench and open the waveform in Surfer
make formal MOD=alu            # run the module's SymbiYosys proof
bash formal/rvfi/run.sh        # run the full riscv-formal proof of the core
make hex PROG=program          # assemble tests/program.s to a hex image
make cosim PROG=cosim1         # lockstep-compare a program against Spike
./synth_stats.sh riscv_single  # report a module's synthesis cost
```

## Synthesis

Synthesized for the Digilent Basys 3 (Xilinx Artix-7). sv2v first converts the SystemVerilog to Verilog-2005, since Yosys cannot parse the package-scoped port types.

| Module | LUTs | Flip-flops | Carry cells |
|--------|------|------------|-------------|
| `pc` | 0 | 32 | 0 |
| `alu_decoder` | 5 | 0 | 0 |
| `control_unit` | 24 | 0 | 0 |
| `control_decoder` | 30 | 0 | 0 |
| `extend` | 31 | 0 | 0 |
| `clint` | 218 | 128 | 22 |
| `alu` | 497 | 0 | 22 |
| `csr` | 752 | 384 | 32 |
| `regfile` | 911 | 992 | 0 |
| `riscv_single` | 2669 | 1418 | 70 |

### Tool versions

Icarus Verilog 13.0, Yosys 0.66, SymbiYosys 0.66 with Yices 2, sv2v 0.0.13, the RISC-V GNU toolchain (`riscv64-elf-gcc` 16.1.0), Spike 1.1.1, Python 3.11, and Surfer.
