#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "==> Verilating..."
verilator --cc --exe --build \
    -Wall \
    --top-module top \
    src/top.sv \
    test/tb_top.cpp \
    -o tb_top

echo "==> Running testbench..."
./obj_dir/tb_top
