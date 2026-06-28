# TakeFive

A RISC-V processor built from scratch in SystemVerilog because I miss taking classes.

## Prerequisites

- [Verilator](https://www.veripool.org/verilator/) (5.x)
- [Yosys](https://yosyshq.net/yosys/) (0.59+)
- C++17 compiler
- Python 3

## Project Structure

```
config.json          Project configuration (top module, source list)
run.py               Build/run script
src/
  core.sv            Top-level core wrapper
  exe.sv             Execution unit
test/
  tb_top.cpp         Main testbench
  dut.h / dut.cpp    DUT wrapper (drives the Verilator model)
  ref.h / ref.cpp    Reference model (pure C++)
```

## Usage

```sh
./run.py ++sim            # Simulate RTL with Verilator
./run.py ++syn            # Synthesize with Yosys
./run.py ++syn ++sim      # Synthesize, then simulate the netlist
```

## Configuration

RTL sources and the top module are defined in `config.json`:

```json
{
    "top": "core",
    "sources": [
        "src/core.sv",
        "src/exe.sv"
    ]
}
```

## TODOs
- Check how the RF gets synthesized (make sure it is using a DistRAM primitive), check how imem and dmem memory gets synthesized
- Add Vivado synthesis + sta scripts or figure out how to perform STA with yosys.
- Make tests such that they take random simple programs written in C, compile them to riscv asm and then check the regfile.
- Consider skid-style pipeline regs to make pipeline slightly more efficient for CPI
