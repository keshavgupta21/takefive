#!/usr/bin/env python3
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SYN_DIR = ROOT / "syn"
CONFIG = json.loads((ROOT / "config.json").read_text())
TOPS = CONFIG["top"]

def run(cmd):
    print(f"==> {cmd[0]}...")
    result = subprocess.run(cmd, cwd=ROOT)
    if result.returncode != 0:
        sys.exit(result.returncode)

def syn():
    SYN_DIR.mkdir(exist_ok=True)
    sources = " ".join(CONFIG["sources"])

    for top in TOPS:
        script = f"""
            read_verilog -sv {sources};
            synth -top {top};
            flatten;
            write_verilog syn/{top}.v;
        """

        print(f"==> Synthesizing {top} with Yosys...")
        result = subprocess.run(
            ["yosys", "-p", script, "-l", str(SYN_DIR / f"{top}.log")],
            cwd=ROOT,
        )
        if result.returncode != 0:
            sys.exit(result.returncode)
        print(f"==> Done. Netlist written to syn/{top}.v")

def sim(use_netlist):
    for top in TOPS:
        if use_netlist:
            sources = [f"syn/{top}.v"]
        else:
            sources = CONFIG["sources"]

        mdir = f"build/{top}"
        (ROOT / mdir).mkdir(parents=True, exist_ok=True)
        lint = ["-Wall"] if not use_netlist else ["-Wall", "-Wno-UNUSEDSIGNAL"]

        run([
            "verilator", "--cc", "--exe", "--build",
            *lint,
            "-CFLAGS", "-std=c++17 -I../../test",
            "--Mdir", mdir,
            "--top-module", top,
            *sources,
            "test/tb_top.cpp",
            "test/ref.cpp",
            "test/dut.cpp",
            "-o", "tb_top",
        ])

        run([str(ROOT / mdir / "tb_top")])

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
