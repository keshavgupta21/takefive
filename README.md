# TakeFive

A RISC-V processor built from scratch in SystemVerilog because I miss taking classes.

## Prerequisites

- [Verilator](https://www.veripool.org/verilator/) (5.x)
- [Yosys](https://yosyshq.net/yosys/) (0.59+)
- C++17 compiler
- Python 3

## Project Structure

```
config.json          Project configuration (source list, sim/syn tops)
run.py               Build/run script
src/
  takefive_pkg.sv    Package: instruction encodings, processor types, cache types
  rtl/               Core RTL
    core.sv          Top-level processor (pipeline + icache + dcache)
    fetch.sv         Stage 1: instruction fetch
    dec.sv           Stage 2: decode
    alu.sv           Stage 3: ALU
    mem.sv           Stage 3: memory request generation
    branch.sv        Stage 3: branch/jump resolution
    bypass.sv        Register file bypass / hazard detection
    wb.sv            Stage 4: writeback
    icache.sv        Direct-mapped instruction cache (256 words, 16-word lines)
    dcache.sv        2-way set-associative data cache (512 words, write-back LRU)
    ram.sv           Parametrized distributed RAM primitive
  util/
    dram_mem.sv      Behavioural DRAM model (fixed 20-cycle latency, cache-line wide)
    delay_mem.sv     Simple word-wide memory with variable latency
    magic_rf.sv      Simulation-only register file with debug ports
  syn/
    syn_rf.sv        Synthesisable register file (two dist-RAM instances)
    core_top.sv      Synthesis top: core + syn_rf, DRAM ports exposed
  wrap/              Verilator test wrappers (flat ports for struct interfaces)
test/
  tb_top.cpp         Main testbench (all test functions + main)
  dut.h / dut.cpp    DUT wrappers (Verilator model drivers)
  ref.h / ref.cpp    Reference model (pure C++)
```

## Usage

```sh
./run.py ++sim            # Simulate RTL with Verilator
./run.py ++syn            # Synthesize core_top with Yosys
./run.py ++sim_syn        # Synthesize all modules, then simulate netlists
./run.py ++sim_waves      # Simulate with VCD waveform output
./run.py ++clean          # Remove build/ and syn/ directories
```

## Architecture

The core is a 4-stage in-order pipeline: **Fetch → Decode → Execute/Mem → Writeback**.

- Instruction memory is served by a direct-mapped **icache** (256 words, CL=16) backed by a `dram_mem` (1024 words).
- Data memory is served by a 2-way set-associative write-back **dcache** (512 words, CL=16) backed by a `dram_mem` (1024 words).
- The `dram_mem` model imposes a fixed 20-cycle latency and transfers one full cache line per request.
- The package (`takefive_pkg.sv`) centralises all parameters and types: `CL_WORDS=16`, `CACHE_DEPTH=16`, address decomposition structs, DRAM interface types, etc.

## Configuration

RTL sources and top modules are declared in `config.json`. Any new `.sv` file must be added to `sources`. `sim_top` lists modules with Verilator wrappers; `syn_top` lists modules to synthesise individually.

## TODOs
- Add Vivado synthesis + sta + util scripts or figure out how to perform STA with yosys.
- Make tests such that they take random simple programs written in C, compile them to riscv asm and then check the regfile.
- Consider skid-style pipeline regs to make pipeline slightly more efficient for CPI
- Check how the RF and cache mems are getting synthesized. I have a feeling we have a really long path in the dcache req -> hit -> write path.
- Remove extra signals from core_top such as dram_inst_req.data since they will be unused and unnecessary?
- Figure out why the CPI is so bad - I think it's just because we're randomly jumping around too much.
- We have some failing tests?
- Find a better solution than WB and WB2 states in dcache