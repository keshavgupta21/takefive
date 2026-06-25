# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TakeFive is a RISC-V processor implemented in SystemVerilog. Currently in early stages with a stub execution unit; the core will grow into a full pipeline.

## Build & Test Commands

```sh
./run.py ++sim            # Build with Verilator and run testbench
./run.py ++syn            # Synthesize with Yosys (output: syn/core.v)
./run.py ++syn ++sim      # Synthesize, then simulate the netlist
```

Build artifacts go to `build/`, synthesis output to `syn/`. Both are gitignored.

## Prerequisites

Verilator 5.x, Yosys 0.59+, C++17 compiler, Python 3.

## Architecture

- **`config.json`** — Declares the top module name and RTL source list. `run.py` reads this to drive both Verilator and Yosys, so new `.sv` files must be added here.
- **`src/`** — SystemVerilog RTL. `core.sv` is the top-level module; submodules (like `exe.sv`) are instantiated inside it.
- **`test/`** — C++ testbench using a dual-model pattern:
  - `Dut` (`dut.h/cpp`) wraps the Verilator-generated model, driving `clk`/`rst` and exposing `step(a, b)` / `result()`.
  - `Ref` (`ref.h/cpp`) is a pure-C++ reference model with the same `step`/`result` interface.
  - `tb_top.cpp` feeds identical stimulus to both and compares outputs each cycle. Add new test vectors to the `tests[]` array.

When adding a new RTL module: create the `.sv` file in `src/`, add it to `config.json` `sources`, and update the `Ref` model to match the expected behavior.

## RTL Coding Guidelines

- Each module or interface must live in a file with the same name (e.g., module `exe` → `exe.sv`).
