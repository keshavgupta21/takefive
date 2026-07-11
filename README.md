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
  common.svh         AXI-Lite and AXI Stream port macros (s_axil_intf, m_axis_intf, …)
  rtl/               Core RTL
    core.sv          Top-level processor (pipeline + shim + icache + dcache + RF)
    fetch.sv         Stage 1: instruction fetch
    dec.sv           Stage 2: decode
    alu.sv           Stage 3: ALU
    mem.sv           Stage 3: memory request generation
    branch.sv        Stage 3: branch/jump resolution
    bypass.sv        Register file bypass / hazard detection
    wb.sv            Stage 4: writeback
    rf.sv            Register file (two distributed-RAM instances)
    shim.sv          MMIO decode, AXI Stream console, AXI-Lite slave bridge
    icache.sv        Direct-mapped instruction cache (16 entries, 16-word lines)
    dcache.sv        Direct-mapped write-back data cache (16 entries, 16-word lines)
    ram.sv           Parametrised distributed RAM primitive
  axi/
    saxil.sv         AXI4-Lite slave: exposes register dump and control registers
    maxil.sv         AXI4 master: translates cache-line DRAM requests to AXI beat-by-beat transfers
  util/
    dram_mem.sv      Behavioural DRAM (20-cycle latency, cache-line wide) — used only in unit-test wrappers
    delay_mem.sv     Word-wide memory with variable latency
  wrap/
    core_wrap.sv     Verilator top: thin wrapper around core; exposes AXI-Lite, AXI Stream, and two AXI4 master buses
    dec_wrap.sv      )
    exe_wrap.sv      )
    branch_wrap.sv   ) Unit-test wrappers — flat ports for struct interfaces
    fetch_wrap.sv    )
    icache_wrap.sv   )
    dcache_wrap.sv   )
test/
  tb_top.cpp         Testbench: unit tests (++unit_test) and core integration test (++core_test)
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
./run.py ++unit_test <unit|all>          # Run unit test(s) against RTL
./run.py ++unit_test ++waves <unit|all>  # Same, with VCD waveform output

# Full-core integration tests
./run.py ++core_test <prog|all>          # Compile and run a program against RTL core
./run.py ++core_test ++waves <prog>      # Same, with VCD written to build/waves.vcd
./run.py ++core_test ++syn               # Synthesize core, then run all program tests

./run.py ++dump <prog>                   # Compile prog and write disassembly to build/imem.lst
./run.py ++clean                         # Remove build/ and syn/
```

`++core_test` compiles the program with `riscv64-unknown-elf-gcc` (rv32i, -O2, -ffreestanding,
-nostdlib), loads the resulting `build/inst.mem` and `build/data.mem` into both a pure-C++
`CoreRef` and a Verilator `CoreDut`, runs both to completion, then compares all 32 MMIO
data words and prints a side-by-side register file table.

## Memory Map

### Processor address space (core-side)

| Range                     | Region                              |
|---------------------------|-------------------------------------|
| `0x00000000 – 0x7FFFFFFF` | Instruction memory (icache-backed)  |
| `0x80000000 – 0xFFFFFEFF` | Data memory (dcache-backed)         |
| `0xFFFFFF00 – 0xFFFFFFFF` | MMIO (64 words, word-addressed)     |

Core routes all data-path accesses: addresses in `0xFFFFFF00–0xFFFFFFFF` bypass the dcache
and are forwarded to the MMIO logic in `shim.sv`; all other addresses go to the dcache after
subtracting `DMEM_VADDR` (`0x80000000`).

**MMIO word map (byte address = `0xFFFFFF00 + word × 4`):**

| Word | Address      | Name     | Direction | Meaning                                 |
|------|--------------|----------|-----------|-----------------------------------------|
| 0    | `0xFFFFFF00` | DATA[0]  | W         | x0 (register dump word, written by runtime) |
| …    | …            | …        | W         | …                                       |
| 31   | `0xFFFFFF7C` | DATA[31] | W         | x31                                     |
| 61   | `0xFFFFFFF4` | RLEVEL   | R         | AXI Stream receive FIFO fill level      |
| 62   | `0xFFFFFFF8` | PUTC     | R/W       | Write: send byte via AXI Stream; Read: receive byte |
| 63   | `0xFFFFFFFC` | EXIT     | W         | Write anything to halt the processor    |

Words 32–60 are reserved and return 0 on read.

### AXI-Lite register map (master-side, byte addresses)

An external AXI4-Lite master (e.g. a Zynq PS or Vivado IP) controls the core through
`saxil.sv`. Address width is 8 bits; data width is 32 bits.

**Read port — register dump (addresses `0x00`–`0x7C`):**

| Byte address | Contents            |
|--------------|---------------------|
| `0x00`       | DATA[0] = x0        |
| …            | …                   |
| `0x7C`       | DATA[31] = x31      |

Reads outside `0x00`–`0x7C` return 0.

**Write port — control registers:**

| Byte address | Register     | Reset | Meaning                        |
|--------------|--------------|-------|--------------------------------|
| `0x80`       | `imem_base`  | `0`   | Instruction memory base address |
| `0x84`       | `imem_bound` | `0`   | Instruction memory bound address |
| `0x88`       | `dmem_base`  | `0`   | Data memory base address        |
| `0x8C`       | `dmem_bound` | `0`   | Data memory bound address       |

## Test Programs

Programs live under `test/prog/`. Each `.c` or `.s` file at the top level of that
directory is a runnable program (invoked with `++core_test <name>`). The `util/` subdirectory
is not directly invocable — it provides the shared startup and runtime linked into every
program:

- `_start` initialises `sp` to `0x80001000` (top of 4 KB DMEM) and jumps to `main`.
- `exit()` and `dump_and_exit()` are available as force-inlined C functions (via
  `util/util.h`) and as callable assembly labels (from `util/util.s`).
- Assembly programs define `main:` and jump directly to `exit` or `dump_and_exit`.
- C programs `#include "util/util.h"` and call them explicitly.

## Architecture

The core is a 4-stage in-order pipeline: **Fetch → Decode → Execute/Mem → Writeback**.

- **Fetch** issues word-addressed reads to the icache → dram_mem (IMEM, 4 KB).
- **Decode** extracts instruction fields and reads the register file.
- **Execute/Mem** computes the ALU result, resolves branches, and issues load/store
  requests. MMIO requests are routed to the shim; dcache requests go directly to the
  dcache. Branches annul the in-flight fetch on a taken path.
- **Writeback** completes loads (stalls until dmem_rsp.vld) and writes the register file.
- **Register file** (`rf.sv`) uses two distributed-RAM instances for simultaneous dual read.
- **Core routing** (`core.sv`) decodes data-path addresses: MMIO addresses
  (`0xFFFFFF00–0xFFFFFFFF`) are forwarded to the shim; everything else goes to the dcache
  after subtracting `DMEM_VADDR` (`0x80000000`). Instruction fetches connect directly from
  the fetch stage to the icache with no shim involvement.
- **Shim** (`shim.sv`) handles MMIO and the AXI master bridges. It receives pre-filtered
  MMIO requests from core, drives the AXI Stream master (putc) and slave (getc/level) for
  console I/O, and generates `dbg_pause` as the OR of an internal exit-latch
  (`dbg_stop_core`, set when the program writes to `EXIT`) and the external `dbg_prog`
  input. It also instantiates two `maxil` AXI master bridges (one for imem, one for dmem)
  driven by `base`/`bound` control registers programmed via the AXI4-Lite slave
  (`saxil.sv`).
- **`dbg_prog`** is an input to `core_wrap` that pauses the pipeline without resetting
  hardware. The testbench asserts it before releasing `rst` to safely program `base`/`bound`
  over the AXI-Lite interface, then deasserts it to start execution. `rst` now has a simple
  hardware-reset meaning only.
- The testbench (`CoreDut`) acts as the AXI4 slave for both memory buses: it responds to
  the DUT's read/write requests in the range `[base, base+DRAM_WORDS*4)` each clock cycle.

## Configuration

RTL sources and top modules are declared in `config.json`:
- `sources` — all `.sv` files compiled by both Verilator and Yosys.
- `sim_top` — modules with Verilator wrappers (each gets its own `build/<top>/` dir).
- `syn_top` — modules synthesised individually by Yosys into `syn/<top>.v`.

`run.py` filters `sources` by prefix when building for synthesis: only `src/rtl/`,
`src/axi/`, and `src/takefive_pkg.sv` are passed to Yosys; wrapper and utility files
are excluded.

## RV32I Limitations

TakeFive implements a subset of the RV32I base integer ISA. The following instructions or behaviours are not yet supported:

**Sub-word memory access (LB, LH, LBU, LHU, SB, SH)**
Only word (32-bit) loads and stores are implemented. The decode stage rejects all other `funct3` encodings for LOAD and STORE as illegal, and the memory interface (`mem_req_t`) has no byte-enable field, so sub-word access is not possible at the hardware level.

**ECALL / EBREAK**
The decoder accepts both instructions (OPC_SYSTEM, funct3 = 0) as valid, but the writeback stage has no handler for OPC_SYSTEM — they silently pass through the pipeline as no-ops. No trap, exception vector, or privileged-mode machinery exists.

**No exception or interrupt support**
There is no trap mechanism of any kind: illegal instructions, misaligned memory accesses, and external interrupts are all silently ignored. This also means there is no way to distinguish ECALL from EBREAK at runtime.

**Misaligned memory access is undefined**
The memory stage computes the effective address without alignment checking. A word load or store to a non-word-aligned address passes an unaligned address to the cache, producing undefined behaviour.

**FENCE is a no-op**
FENCE (OPC_FENCE, funct3 = 0) is decoded as valid but neither the execute nor the writeback stage enforces any memory-ordering semantics. For this single-core, in-order pipeline the ordering happens to be correct regardless, but the instruction is not architecturally implemented.

## TODOs

- Add Vivado syn + sta + impl scripts; get it running on the Pynq Z2.
- Bring in the official RISC-V compliance/certification test suite.
- Consider skid-style pipeline registers for better CPI.
- Consider skid-style pipeline registers for memory requests.
- Investigate the dcache req → hit → write critical path.
- Add CPI reporting to tests.
- Add exceptions/interrupts at-least for illegal instructions.
- Add branch penalty, cache miss, cache hit, etc counters.
- Remove extra copies of exit and dump and exit from final instruction memory
- Extend the dirty in data cache to be 16 bits so we only write back the words that are actually dirty
