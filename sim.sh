#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "==> Verilating..."
verilator --cc --exe --build \
    -Wall \
    -CFLAGS "-std=c++17" \
    --Mdir build \
    --top-module top \
    src/top.sv \
    test/tb_top.cpp \
    -o tb_top

echo "==> Running testbench..."
./build/tb_top
