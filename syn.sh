#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

mkdir -p syn

echo "==> Synthesizing with Yosys..."
yosys -p "
    read_verilog -sv src/top.sv;
    synth -top top;
    write_verilog syn/netlist.v;
" -l syn/yosys.log

echo "==> Done. Netlist written to syn/netlist.v"
