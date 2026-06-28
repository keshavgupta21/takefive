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

def verilator_root():
    return subprocess.check_output(
        ["verilator", "--getenv", "VERILATOR_ROOT"], text=True
    ).strip()

def syn():
    SYN_DIR.mkdir(exist_ok=True)
    sources = " ".join(CONFIG["sources"])

    for top in TOPS:
        script = f"""
            read_verilog -sv -I src {sources};
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

def sim(use_netlist, use_waves):
    # Phase 1: verilate all top modules (model libraries only)
    for top in TOPS:
        if use_netlist:
            sources = [f"syn/{top}.v"]
        else:
            sources = CONFIG["sources"]

        mdir = f"build/{top}"
        (ROOT / mdir).mkdir(parents=True, exist_ok=True)

        lint_off = ["-Wno-UNUSEDPARAM", "-Wno-UNUSEDSIGNAL"]
        trace_flags = ["--trace", "--trace-structs"] if use_waves else []

        run([
            "verilator", "--cc", "--build",
            "-Wall", *lint_off,
            "-CFLAGS", "-std=c++17",
            "-Isrc",
            "--Mdir", mdir,
            "--top-module", top,
            *trace_flags,
            *sources,
        ])

    # Phase 2: compile testbench once, link against all models
    vinc = f"{verilator_root()}/include"
    first = f"build/{TOPS[0]}"

    inc_flags = [f"-Ibuild/{top}" for top in TOPS]
    inc_flags += ["-Itest", f"-I{vinc}", f"-I{vinc}/vltstd"]

    archives = [f"build/{top}/V{top}__ALL.a" for top in TOPS]
    waves_flags = ["-DWAVES"] if use_waves else []
    trace_objs = [f"{first}/verilated_vcd_c.o"] if use_waves else []

    (ROOT / "build").mkdir(parents=True, exist_ok=True)

    run([
        "c++", "-std=c++17", "-Os",
        *inc_flags, "-DVERILATOR=1", *waves_flags,
        "test/tb_top.cpp", "test/ref.cpp", "test/dut.cpp",
        f"{first}/verilated.o", f"{first}/verilated_threads.o",
        *trace_objs,
        *archives,
        "-Wl,-U,__Z15vl_time_stamp64v,-U,__Z13sc_time_stampv",
        "-pthread", "-lpthread",
        "-o", "build/tb_top",
    ])

    tb_cmd = [str(ROOT / "build" / "tb_top")]
    if use_netlist:
        tb_cmd.append("++syn")
    if use_waves:
        tb_cmd.append("++waves")
    run(tb_cmd)

def clean():
    import shutil
    for d in [ROOT / "build", SYN_DIR]:
        if d.exists():
            shutil.rmtree(d)
            print(f"==> Removed {d.relative_to(ROOT)}/")

def main():
    args = set(sys.argv[1:])
    do_syn   = "++syn" in args
    do_sim   = "++sim" in args
    do_clean = "++clean" in args
    do_waves = "++waves" in args

    if do_waves and do_syn:
        print("Error: ++waves and ++syn cannot be used together")
        sys.exit(1)

    if not do_syn and not do_sim and not do_clean:
        print("Usage: ./run.py ++sim [++syn] [++waves]")
        print("  ++sim            Simulate with Verilator")
        print("  ++syn            Synthesize with Yosys")
        print("  ++sim ++syn      Synthesize, then simulate the netlist")
        print("  ++sim ++waves    Simulate with VCD waveform output")
        print("  ++clean          Remove build/ and syn/")
        sys.exit(1)

    if do_clean:
        clean()

    if do_syn:
        syn()

    if do_sim:
        sim(use_netlist=do_syn, use_waves=do_waves)

if __name__ == "__main__":
    main()
