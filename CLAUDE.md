# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TakeFive is a RISC-V processor implemented in SystemVerilog. It implements a 4-stage in-order pipeline (Fetch → Decode → Execute/Mem → Writeback) with icache, dcache, MMIO, and AXI4 master interfaces.

## Build & Test Commands

```sh
./run.py ++unit_test <unit|all>   # Run unit tests (dec, exe, branch, fetch, icache, dcache)
./run.py ++core_test <prog|all>   # Run core integration tests
./run.py ++core_test ++syn        # Synthesize core, then run all core tests
./run.py ++dump <prog>            # Compile prog and write disassembly to build/imem.lst
./run.py ++clean                  # Remove build/ and syn/
```

Build artifacts go to `build/<top>/`, synthesis output to `syn/`. Both are gitignored.

**Always use `run.py` for building and testing. Never invoke `verilator` or `yosys` directly.**

## Prerequisites

Verilator 5.x, Yosys 0.59+, C++17 compiler, Python 3.

## Architecture

- **`config.json`** — Declares the list of top modules and RTL source list. `run.py` reads this to drive both Verilator and Yosys for each top module, so new `.sv` files must be added here.
- **`src/`** — SystemVerilog RTL. `core.sv` is the top-level module; submodules (`dec.sv`, `alu.sv`, `mem.sv`, `branch.sv`, `shim.sv`, etc.) are instantiated inside it.
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
- Align `=` and `<=` operators within a group of assignments. Also align port names in module port lists. In module instantiations, put `(` after the instance name and `);` after the last port connection. Align the closing `)` of each port connection so they form a vertical column (e.g., `.clk   (clk   ),`). Apply alignment rules at the user's request to recently modified files.
  - Example:
  ```
  dec u_dec(
      .f_pc   (f_pc  ),
      .f_inst (f_inst),
      .d_pc   (d_pc  ),
      .d_inst (d_inst)
  );
  ```
- In module port declarations, separate logically distinct groups of ports with blank lines (e.g., clk/rst, read ports, write ports). Instantiations do not need blank lines.
- When a block keyword (`always_ff`, `always_comb`, `if`, `else`, `for`, etc.) has a body that fits on one line (≤ 65 columns total), put it on the same line — no `begin`/`end` needed (e.g., `if (rst) pc <= 0;` / `else pc <= pc + 4;`). Must use `begin`/`end` whenever the body spans more than one line or has more than one statement. This rule applies equally to `always_ff`/`always_comb` — a multi-line body must be wrapped in `begin`/`end`.
- Never use `wire` or `reg`. Always use `logic` and assign on a separate line (e.g., `logic foo; assign foo = bar;` instead of `wire foo = bar;`).
- Do not use `import`; refer to package items with `::` (e.g., `takefive_pkg::inst_t`).
- Never add lint suppression pragmas or comments (e.g., `verilator lint_off`). Fix the underlying issue instead. The only exceptions are in `run.py`: `-Wno-UNUSEDPARAM` (shared package constants are intentionally unused in some per-top compilation units) and `-Wno-UNUSEDSIGNAL` (shared struct types carry fields not used by every module).
