#!/usr/bin/env python3
import json
import struct
import subprocess
import sys
from pathlib import Path

ROOT       = Path(__file__).resolve().parent
SYN_DIR    = ROOT / "syn"
CONFIG     = json.loads((ROOT / "config.json").read_text())
DRAM_WORDS = 1024
RISCV_PFX  = "riscv64-unknown-elf"


class _Tee:
    def __init__(self, stream, logfile):
        self._stream  = stream
        self._logfile = logfile

    def write(self, data):
        self._stream.write(data)
        self._logfile.write(data)

    def flush(self):
        self._stream.flush()
        self._logfile.flush()

    def fileno(self):
        return self._stream.fileno()


def run(cmd, quiet=False):
    if not quiet:
        print(f"==> {cmd[0]}...")
        sys.stdout.flush()
    if quiet:
        proc = subprocess.run(
            cmd, cwd=ROOT,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            text=True,
        )
        if proc.returncode != 0:
            sys.stdout.write(proc.stdout)
            sys.exit(proc.returncode)
    else:
        proc = subprocess.Popen(
            cmd, cwd=ROOT,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            text=True, bufsize=1,
        )
        for line in proc.stdout:
            sys.stdout.write(line)
            sys.stdout.flush()
        proc.wait()
        if proc.returncode != 0:
            sys.exit(proc.returncode)


def run_capture(cmd):
    """Run command, return (exit_code, combined_output_string)."""
    proc = subprocess.run(
        cmd, cwd=ROOT,
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        text=True,
    )
    return proc.returncode, proc.stdout


def verilator_root():
    return subprocess.check_output(
        ["verilator", "--getenv", "VERILATOR_ROOT"], text=True
    ).strip()


def _syn_sources():
    return [s for s in CONFIG["sources"]
            if s.startswith("src/rtl/") or s == "src/takefive_pkg.sv"]


def syn_modules():
    SYN_DIR.mkdir(exist_ok=True)
    sources = " ".join(_syn_sources())

    for top in CONFIG["syn_top"]:
        script = f"""
            read_verilog -sv -I src -D SYNTHESIS {sources};
            synth -top {top};
            flatten;
            write_verilog syn/{top}.v;
        """

        print(f"==> Synthesizing {top} with Yosys...")
        run(["yosys", "-p", script, "-l", str(SYN_DIR / f"{top}.log")])
        print(f"==> Done. Netlist written to syn/{top}.v")


def build_tb(use_netlist=False, use_waves=False, quiet=False):
    sim_tops = CONFIG["sim_top"]

    for top in sim_tops:
        if use_netlist:
            netlists = [f"syn/{t}.v" for t in CONFIG["syn_top"]]
            syn_names = set(CONFIG["syn_top"])
            nosyn = [s for s in CONFIG["sources"]
                     if not s.startswith("src/rtl/") and not s.startswith("src/syn/")
                     and Path(s).stem not in syn_names]
            sources = nosyn + netlists
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
        ], quiet=quiet)

    vinc = f"{verilator_root()}/include"
    first = f"build/{sim_tops[0]}"

    inc_flags = [f"-Ibuild/{top}" for top in sim_tops]
    inc_flags += ["-Itest", f"-I{vinc}", f"-I{vinc}/vltstd"]

    archives = [f"build/{top}/V{top}__ALL.a" for top in sim_tops]
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
    ], quiet=quiet)


def sim(use_waves=False):
    build_tb(use_waves=use_waves)
    tb_cmd = [str(ROOT / "build" / "tb_top")]
    if use_waves:
        tb_cmd.append("++waves")
    run(tb_cmd)


def sim_syn():
    syn_modules()
    build_tb(use_netlist=True)
    run([str(ROOT / "build" / "tb_top"), "++syn"])


def compile_prog(progname, quiet=False):
    build = ROOT / "build"
    build.mkdir(parents=True, exist_ok=True)

    for ext in (".c", ".s"):
        src = ROOT / "test" / "prog" / (progname + ext)
        if src.exists():
            break
    else:
        print(f"Error: test/prog/{progname}.c or .s not found")
        sys.exit(1)

    elf  = build / f"{progname}.elf"
    ibin = build / "inst.bin"
    dbin = build / "data.bin"

    util_s = ROOT / "test" / "prog" / "util" / "util.s"
    sources = [str(src)]
    if util_s.exists():
        sources.append(str(util_s))

    run([f"{RISCV_PFX}-gcc", "-march=rv32i", "-mabi=ilp32",
         "-nostdlib", "-ffreestanding", "-O2", "-flto", "-I", "test/prog",
         "-T", "test/prog/util/link.ld",
         "-o", str(elf), *sources], quiet=quiet)

    run([f"{RISCV_PFX}-objcopy",
         "--only-section=.text", "-O", "binary", str(elf), str(ibin)], quiet=quiet)
    run([f"{RISCV_PFX}-objcopy",
         "--only-section=.rodata", "--only-section=.data", "--only-section=.bss",
         "-O", "binary", str(elf), str(dbin)], quiet=quiet)

    def to_mem(bin_path, mem_path):
        raw = bin_path.read_bytes() if bin_path.exists() else b""
        with open(mem_path, "w") as f:
            for i in range(DRAM_WORDS):
                off = i * 4
                if off + 4 <= len(raw):
                    word = struct.unpack_from("<I", raw, off)[0]
                elif off < len(raw):
                    chunk = raw[off:] + bytes(4 - (len(raw) - off))
                    word = struct.unpack_from("<I", chunk)[0]
                else:
                    word = 0
                f.write(f"{word:08x}\n")

    to_mem(ibin, build / "inst.mem")
    to_mem(dbin, build / "data.mem")
    if not quiet:
        print(f"==> build/inst.mem and build/data.mem written ({DRAM_WORDS} words each)")


def dump(progname):
    compile_prog(progname)
    elf      = ROOT / "build" / f"{progname}.elf"
    lst_path = ROOT / "build" / "imem.lst"
    print(f"==> {RISCV_PFX}-objdump...")
    with open(lst_path, "w") as f:
        subprocess.run(
            [f"{RISCV_PFX}-objdump", "-d", "-M", "no-aliases", str(elf)],
            cwd=ROOT, stdout=f, check=True,
        )
    print(f"==> build/imem.lst written")


def test(progname, use_netlist=False, use_waves=False):
    compile_prog(progname)
    if use_netlist:
        syn_modules()
    build_tb(use_netlist=use_netlist, use_waves=use_waves)
    tb_cmd = [str(ROOT / "build" / "tb_top"), "++prog", "++name", progname]
    if use_waves:
        tb_cmd.append("++waves")
    run(tb_cmd)


def test_all():
    prog_dir = ROOT / "test" / "prog"
    progs = sorted(
        p.stem for p in prog_dir.iterdir()
        if p.is_file() and p.suffix in (".c", ".s")
    )
    if not progs:
        print("No test programs found in test/prog/")
        return

    build_tb(quiet=True)

    passed = 0
    failed = []
    for name in progs:
        compile_prog(name, quiet=True)
        rc, output = run_capture([
            str(ROOT / "build" / "tb_top"), "++prog", "++quiet", "++name", name
        ])
        if rc == 0:
            passed += 1
            lines = [l for l in output.splitlines() if l.strip()]
            print(lines[-1] if lines else f"{name}: PASS")
        else:
            failed.append(name)
            sys.stdout.write(output)

    total = len(progs)
    print(f"\n{passed}/{total} tests passed")
    if failed:
        print(f"FAILED: {', '.join(failed)}")


def clean():
    import shutil
    for d in [ROOT / "build", SYN_DIR]:
        if d.exists():
            shutil.rmtree(d)
            print(f"==> Removed {d.relative_to(ROOT)}/")


def main():
    argv = sys.argv[1:]
    flags = set(argv)

    progname = None
    _test_flags = ("++test", "++test_syn", "++test_waves", "++dump")
    for tf in _test_flags:
        if tf in flags:
            idx = argv.index(tf)
            if idx + 1 < len(argv) and not argv[idx + 1].startswith("++"):
                progname = argv[idx + 1]
            else:
                print(f"Usage: ./run.py {tf} <progname>")
                sys.exit(1)
            break

    do_test       = "++test"       in flags
    do_test_syn   = "++test_syn"   in flags
    do_test_waves = "++test_waves" in flags
    do_test_all   = "++test_all"   in flags
    do_dump       = "++dump"       in flags
    do_sim        = "++sim"        in flags
    do_sim_waves  = "++sim_waves"  in flags
    do_sim_syn    = "++sim_syn"    in flags
    do_clean      = "++clean"      in flags

    if not (do_sim or do_sim_waves or do_sim_syn or do_clean
            or do_test or do_test_syn or do_test_waves or do_test_all
            or do_dump):
        print("Usage: ./run.py <mode>")
        print("  ++test <prog>       Compile and run prog against RTL core")
        print("  ++test_syn <prog>   Compile and run prog against synthesized core")
        print("  ++test_waves <prog> Compile and run prog with VCD waveform output")
        print("  ++test_all          Compile and run all programs in test/prog/")
        print("  ++dump <prog>       Compile prog and write disassembly to build/imem.lst")
        print("  ++sim               Simulate with Verilator")
        print("  ++sim_waves         Simulate with VCD waveform output")
        print("  ++sim_syn           Synthesize modules, then simulate netlists")
        print("  ++clean             Remove build/ and syn/")
        sys.exit(1)

    if do_clean:
        clean()

    if do_sim or do_sim_waves or do_sim_syn or do_test or do_test_syn or do_test_waves or do_test_all or do_dump:
        (ROOT / "build").mkdir(parents=True, exist_ok=True)
        log_path = ROOT / "build" / "test.log"
        orig_stdout = sys.stdout
        orig_stderr = sys.stderr
        logfile = open(log_path, "w")
        try:
            sys.stdout = _Tee(orig_stdout, logfile)
            sys.stderr = _Tee(orig_stderr, logfile)

            if do_sim:
                sim()

            if do_sim_waves:
                sim(use_waves=True)

            if do_sim_syn:
                sim_syn()

            if do_test:
                test(progname)

            if do_test_syn:
                test(progname, use_netlist=True)

            if do_test_waves:
                test(progname, use_waves=True)

            if do_test_all:
                test_all()

            if do_dump:
                dump(progname)
        finally:
            sys.stdout = orig_stdout
            sys.stderr = orig_stderr
            logfile.close()


if __name__ == "__main__":
    main()
