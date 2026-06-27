# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TakeFive is a RISC-V processor implemented in SystemVerilog. Currently in early stages with a stub execution unit; the core will grow into a full pipeline.

## Build & Test Commands

```sh
./run.py ++sim            # Build with Verilator and run testbench
./run.py ++syn            # Synthesize with Yosys (output: syn/<top>.v)
./run.py ++syn ++sim      # Synthesize, then simulate the netlist
```

Build artifacts go to `build/<top>/`, synthesis output to `syn/`. Both are gitignored.

**Always use `run.py` for building and testing. Never invoke `verilator` or `yosys` directly.**

## Prerequisites

Verilator 5.x, Yosys 0.59+, C++17 compiler, Python 3.

## Architecture

- **`config.json`** — Declares the list of top modules and RTL source list. `run.py` reads this to drive both Verilator and Yosys for each top module, so new `.sv` files must be added here.
- **`src/`** — SystemVerilog RTL. `core.sv` is the top-level module; submodules (like `exe.sv`, `dec.sv`) are instantiated inside it.
- **`src/intf/`** — SystemVerilog interface definitions (e.g., `f2d_intf.sv`, `d2r_intf.sv`).
- **`src/wrap/`** — Verilator test wrappers that expose flat ports for modules with interface ports (e.g., `dec_wrap.sv`).
- **`test/`** — C++ testbench using a dual-model pattern:
  - `Dut` (`dut.h/cpp`) wraps the Verilator-generated model.
  - `Ref` (`ref.h/cpp`) is a pure-C++ reference model (decode logic, encoding helpers).
  - `tb_top.cpp` contains per-module test functions (e.g., `test_dec`) called from `main`. Each compares DUT output against the reference model.

When adding a new RTL module: create the `.sv` file in `src/`, add it to `config.json` `sources`, and update the `Ref` model to match the expected behavior.

## RTL Coding Guidelines

- Each module or interface must live in a file with the same name (e.g., module `exe` → `exe.sv`).
- Interfaces go in `src/intf/`, test wrappers in `src/wrap/`.
- Testbenches (reference models, stimulus, checks) must be written solely from the spec (`docs/`), never by reading RTL source.
- Do not modify code (ref, dut, or RTL) when testing reveals a bug. Present the analysis and await further instructions.
- Align `=` and `<=` operators within a group of assignments. Also align port names in module port lists. Apply alignment rules after every RTL change.
- In module port declarations, separate logically distinct groups of ports with blank lines (e.g., clk/rst, read ports, write ports). Instantiations do not need blank lines.
- In module instantiations, put `(` and `);` on their own lines at the same indent as the instance name. Align the closing `)` of each port connection so they form a vertical column (e.g., `.clk   (clk   ),`).
- When each branch of an `if`/`else`/`for` contains a single statement, put the statement on the same line as the keyword — no `begin`/`end` needed (e.g., `if (rst) pc <= 0;` / `else pc <= pc + 4;`). Use `begin`/`end` only when a branch has multiple statements.
- Do not use `import`; refer to package items with `::` (e.g., `takefive_pkg::inst_t`).
- Never add lint suppression pragmas or comments (e.g., `verilator lint_off`). Fix the underlying issue instead. The only exceptions are in `run.py`: `-Wno-UNUSEDPARAM` (shared package constants are intentionally unused in some per-top compilation units) and `-Wno-UNUSEDSIGNAL` (shared struct types carry fields not used by every module).
