#!/usr/bin/env python3
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SYN_DIR = ROOT / "syn"
CONFIG = json.loads((ROOT / "config.json").read_text())

def run(cmd):
    print(f"==> {cmd[0]}...")
    result = subprocess.run(cmd, cwd=ROOT)
    if result.returncode != 0:
        sys.exit(result.returncode)

def syn():
    SYN_DIR.mkdir(exist_ok=True)

    sources = " ".join(CONFIG["sources"])
    script = f"""
        read_verilog -sv {sources};
        synth -top {CONFIG["top"]};
        flatten;
        write_verilog syn/{CONFIG["top"]}.v;
    """

    print("==> Synthesizing with Yosys...")
    result = subprocess.run(
        ["yosys", "-p", script, "-l", str(SYN_DIR / "yosys.log")],
        cwd=ROOT,
    )
    if result.returncode != 0:
        sys.exit(result.returncode)
    print(f"==> Done. Netlist written to syn/{CONFIG['top']}.v")

def sim(use_netlist):
    if use_netlist:
        sources = [f"syn/{CONFIG['top']}.v"]
    else:
        sources = CONFIG["sources"]

    run([
        "verilator", "--cc", "--exe", "--build",
        "-Wall",
        "-CFLAGS", "-std=c++17 -I../../test",
        "--Mdir", "build",
        "--top-module", CONFIG["top"],
        *sources,
        "test/tb_top.cpp",
        "test/ref.cpp",
        "test/dut.cpp",
        "-o", "tb_top",
    ])

    run([str(ROOT / "build" / "tb_top")])

def main():
    args = set(sys.argv[1:])
    do_syn = "++syn" in args
    do_sim = "++sim" in args

    if not do_syn and not do_sim:
        print("Usage: ./run.py ++sim [++syn]")
        print("  ++sim        Simulate with Verilator")
        print("  ++syn        Synthesize with Yosys")
        print("  ++sim ++syn  Synthesize, then simulate the netlist")
        sys.exit(1)

    if do_syn:
        syn()

    if do_sim:
        sim(use_netlist=do_syn)

if __name__ == "__main__":
    main()
