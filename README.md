# TakeFive

A RISC-V processor built from scratch in SystemVerilog because I miss taking classes.

## Prerequisites

- [Verilator](https://www.veripool.org/verilator/) (5.x)
- [Yosys](https://yosyshq.net/yosys/) (0.59+)
- C++17 compiler
- Python 3
- RISC-V GCC toolchain (`riscv64-unknown-elf-gcc` or `riscv32-unknown-elf-gcc`)

## Project Structure

```
config.json          Project configuration (source list, sim/syn tops)
run.py               Build/run/test script
src/
  takefive_pkg.sv    Package: instruction encodings, processor types, cache types
  rtl/               Core RTL
    core.sv          Top-level processor (pipeline + MMU + icache + dcache + RF)
    fetch.sv         Stage 1: instruction fetch
    dec.sv           Stage 2: decode
    alu.sv           Stage 3: ALU
    mem.sv           Stage 3: memory request generation
    branch.sv        Stage 3: branch/jump resolution
    bypass.sv        Register file bypass / hazard detection
    wb.sv            Stage 4: writeback
    rf.sv            Register file (two distributed-RAM instances)
    mmu.sv           Memory map unit (routes dmem to dcache or MMIO)
    icache.sv        Direct-mapped instruction cache (16 entries, 16-word lines)
    dcache.sv        Direct-mapped write-back data cache (16 entries, 16-word lines)
    ram.sv           Parametrised distributed RAM primitive
  util/
    dram_mem.sv      Behavioural DRAM (20-cycle latency, cache-line wide, BASE-aware OOB)
    delay_mem.sv     Word-wide memory with variable latency
  wrap/
    core_wrap.sv     Verilator top: core + u_imem + u_dmem, flat MMIO ports
    dec_wrap.sv      )
    exe_wrap.sv      )
    branch_wrap.sv   ) Unit-test wrappers — flat ports for struct interfaces
    fetch_wrap.sv    )
    icache_wrap.sv   )
    dcache_wrap.sv   )
test/
  tb_top.cpp         Testbench: unit tests (++sim) and core integration test (++prog)
  dut.h / dut.cpp    DUT wrappers (Verilator model drivers), including CoreDut
  ref.h / ref.cpp    Reference model (pure C++), including CoreRef
  prog/              RISC-V test programs
    util/
      link.ld        Linker script (IMEM @ 0x0, DMEM @ 0x80000000, both 4 KB)
      util.s         Startup (_start → j main) and runtime (exit, dump_and_exit)
      util.h         Force-inline C declarations of exit() and dump_and_exit()
    helloc.c         Hello world in C
    hellos.s         Hello world in assembly
```

## Usage

```sh
# Unit tests (decode, execute, branch, fetch, icache, dcache)
./run.py ++sim            # Simulate RTL with Verilator
./run.py ++sim_waves      # Simulate with VCD waveform output
./run.py ++sim_syn        # Synthesize all modules, then simulate netlists
./run.py ++syn            # Synthesize core_top with Yosys

# Full-core integration tests
./run.py ++test <prog>       # Compile test/prog/<prog>.c/.s and run against RTL core
./run.py ++test_waves <prog> # Same, with VCD written to build/waves.vcd
./run.py ++test_syn <prog>   # Same, against synthesized core netlist

./run.py ++clean          # Remove build/ and syn/
```

`++test` compiles the program with `riscv64-unknown-elf-gcc` (rv32i, -O2, -ffreestanding,
-nostdlib), loads the resulting `build/inst.mem` and `build/data.mem` into both a pure-C++
`CoreRef` and a Verilator `CoreDut`, runs both to completion, then compares all 64 MMIO
words and prints a side-by-side register file table.

## Memory Map

| Range                     | Region                              |
|---------------------------|-------------------------------------|
| `0x00000000 – 0x7FFFFFFF` | Instruction memory (icache-backed)  |
| `0x80000000 – 0xFFFFFEFF` | Data memory (dcache-backed)         |
| `0xFFFFFF00 – 0xFFFFFFFF` | MMIO (64 words, word-addressed)     |

The MMU routes all data-path accesses: non-MMIO addresses go to the dcache, MMIO
addresses bypass the cache and appear on the flat `mmio_req/rsp/rdy` ports of `core_wrap`.

**MMIO conventions used by the test runtime:**

| Address      | Meaning                              |
|--------------|--------------------------------------|
| `0xFFFFFF00` | MMIO[0] = x0 (dump_and_exit)        |
| `0xFFFFFF04` | MMIO[1] = x1                        |
| …            | …                                    |
| `0xFFFFFF7C` | MMIO[31] = x31                      |
| `0xFFFFFFFC` | `sw x0, -4(x0)` — halt signal       |

## Test Programs

Programs live under `test/prog/`. Each `.c` or `.s` file at the top level of that
directory is a runnable program (invoked with `++test <name>`). The `util/` subdirectory
is not directly invocable — it provides the shared startup and runtime linked into every
program:

- `_start` initialises `sp` to `0x80001000` (top of 4 KB DMEM) and jumps to `main`.
- `exit()` and `dump_and_exit()` are available as force-inlined C functions (via
  `util/util.h`) and as callable assembly labels (from `util/util.s`).
- Assembly programs define `main:` and jump directly to `exit` or `dump_and_exit`.
- C programs `#include "util/util.h"` and call them explicitly.

## Architecture

The core is a 4-stage in-order pipeline: **Fetch → Decode → Execute/Mem → Writeback**.

- **Fetch** issues word-addressed reads to the MMU → icache → dram_mem (IMEM, 4 KB).
- **Decode** extracts instruction fields and reads the register file.
- **Execute/Mem** computes the ALU result, resolves branches, and issues load/store
  requests to the MMU. Branches annul the in-flight fetch on a taken path.
- **Writeback** completes loads (stalls until dmem_rsp.vld) and writes the register file.
- **Register file** (`rf.sv`) uses two distributed-RAM instances for simultaneous dual read.
- **MMU** (`mmu.sv`) splits the data path: addresses in `0xFFFFFF00–0xFFFFFFFF` route to
  MMIO, everything else routes to the dcache.
- `dram_mem` models a 20-cycle-latency DRAM with cache-line granularity. It accepts a
  `BASE` parameter for OOB detection; `core_wrap` passes `0x80000000` for DMEM.

## Configuration

RTL sources and top modules are declared in `config.json`:
- `sources` — all `.sv` files compiled by both Verilator and Yosys.
- `sim_top` — modules with Verilator wrappers (each gets its own `build/<top>/` dir).
- `syn_top` — modules synthesised individually by Yosys into `syn/<top>.v`.

## TODOs

- Add Vivado syn + sta + impl scripts; get it running on the Pynq Z2.
- Bring in the official RISC-V compliance/certification test suite.
- Consider skid-style pipeline registers for better CPI.
- Investigate the dcache req → hit → write critical path.
- Figure out why unit-test CPI is high (likely excess random branches in the random test).
