#!/usr/bin/env python3
import contextlib
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

UNITS = ["dec", "exe", "branch", "fetch", "icache", "dcache"]


# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------

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


@contextlib.contextmanager
def _tee_log():
    (ROOT / "build").mkdir(parents=True, exist_ok=True)
    log_path = ROOT / "build" / "test.log"
    orig_out, orig_err = sys.stdout, sys.stderr
    with open(log_path, "w") as lf:
        sys.stdout = _Tee(orig_out, lf)
        sys.stderr = _Tee(orig_err, lf)
        try:
            yield
        finally:
            sys.stdout = orig_out
            sys.stderr = orig_err


def run(cmd, quiet=False):
    if not quiet:
        print(f"==> {cmd[0]}...")
        sys.stdout.flush()
    if quiet:
        proc = subprocess.run(
            cmd, cwd=ROOT,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
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
    proc = subprocess.run(
        cmd, cwd=ROOT,
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
    )
    return proc.returncode, proc.stdout


def _err(msg):
    print(USAGE)
    print(f"error: {msg}")
    sys.exit(1)


# ---------------------------------------------------------------------------
# Verilator / build helpers
# ---------------------------------------------------------------------------

def verilator_root():
    return subprocess.check_output(
        ["verilator", "--getenv", "VERILATOR_ROOT"], text=True
    ).strip()


def _link_tb(sim_tops, sources, waves=False, quiet=False):
    vinc  = f"{verilator_root()}/include"
    first = f"build/{sim_tops[0]}"

    inc_flags   = [f"-Ibuild/{t}" for t in sim_tops]
    inc_flags  += ["-Itest", f"-I{vinc}", f"-I{vinc}/vltstd"]
    archives    = [f"build/{t}/V{t}__ALL.a" for t in sim_tops]
    waves_flags = ["-DWAVES"] if waves else []
    trace_objs  = [f"{first}/verilated_vcd_c.o"] if waves else []

    run([
        "c++", "-std=c++17", "-Os",
        *inc_flags, "-DVERILATOR=1", *waves_flags,
        "test/tb_top.cpp", "test/ref.cpp", "test/dut.cpp",
        f"{first}/verilated.o", f"{first}/verilated_threads.o",
        *trace_objs, *archives,
        "-Wl,-U,__Z15vl_time_stamp64v,-U,__Z13sc_time_stampv",
        "-pthread", "-lpthread",
        "-o", "build/tb_top",
    ], quiet=quiet)


def build_tb(waves=False, quiet=False):
    sim_tops    = CONFIG["sim_top"]
    sources     = CONFIG["sources"]
    lint_off    = ["-Wno-UNUSEDPARAM", "-Wno-UNUSEDSIGNAL"]
    trace_flags = ["--trace", "--trace-structs"] if waves else []

    for top in sim_tops:
        mdir = f"build/{top}"
        (ROOT / mdir).mkdir(parents=True, exist_ok=True)
        run([
            "verilator", "--cc", "--build",
            "-Wall", *lint_off, "-CFLAGS", "-std=c++17",
            "-Isrc", "--Mdir", mdir, "--top-module", top,
            *trace_flags, *sources,
        ], quiet=quiet)

    _link_tb(sim_tops, sources, waves=waves, quiet=quiet)


def build_tb_syn(quiet=False):
    (SYN_DIR).mkdir(exist_ok=True)

    rtl_sources = [s for s in CONFIG["sources"]
                   if s.startswith("src/rtl/") or s.startswith("src/axi/")
                   or s == "src/takefive_pkg.sv"]
    script = (
        f"read_verilog -sv -I src -D SYNTHESIS {' '.join(rtl_sources)};"
        f" synth -top core; flatten; write_verilog syn/core.v;"
    )
    print("==> Synthesizing core with Yosys...")
    run(["yosys", "-p", script, "-l", str(SYN_DIR / "core.log")], quiet=quiet)

    sim_tops = CONFIG["sim_top"]
    sources  = [s for s in CONFIG["sources"] if Path(s).stem != "core"] + ["syn/core.v"]
    lint_off = ["-Wno-UNUSEDPARAM", "-Wno-UNUSEDSIGNAL"]

    for top in sim_tops:
        mdir = f"build/{top}"
        (ROOT / mdir).mkdir(parents=True, exist_ok=True)
        run([
            "verilator", "--cc", "--build",
            "-Wall", *lint_off, "-CFLAGS", "-std=c++17",
            "-Isrc", "--Mdir", mdir, "--top-module", top,
            *sources,
        ], quiet=quiet)

    _link_tb(sim_tops, sources, waves=False, quiet=quiet)


# ---------------------------------------------------------------------------
# Program compilation
# ---------------------------------------------------------------------------

def compile_to_bytes(progname, quiet=False):
    build = ROOT / "build"
    build.mkdir(parents=True, exist_ok=True)

    for ext in (".c", ".s"):
        src = ROOT / "test" / "prog" / (progname + ext)
        if src.exists():
            break
    else:
        _err(f"test/prog/{progname}.c or .s not found")

    elf  = build / f"{progname}.elf"
    ibin = build / "inst.bin"
    dbin = build / "data.bin"

    util_s  = ROOT / "test" / "prog" / "util" / "util.s"
    sources = [str(src)] + ([str(util_s)] if util_s.exists() else [])

    run([f"{RISCV_PFX}-gcc", "-march=rv32i", "-mabi=ilp32",
         "-nostdlib", "-ffreestanding", "-O2", "-flto", "-I", "test/prog",
         "-T", "test/prog/util/link.ld",
         "-o", str(elf), *sources], quiet=quiet)

    run([f"{RISCV_PFX}-objcopy",
         "--only-section=.text", "-O", "binary", str(elf), str(ibin)],
        quiet=quiet)
    run([f"{RISCV_PFX}-objcopy",
         "--only-section=.rodata", "--only-section=.data", "--only-section=.bss",
         "-O", "binary", str(elf), str(dbin)],
        quiet=quiet)

    imem_bytes = ibin.read_bytes() if ibin.exists() else b""
    dmem_bytes = dbin.read_bytes() if dbin.exists() else b""
    return imem_bytes, dmem_bytes


def compile_prog(progname, quiet=False):
    build = ROOT / "build"
    imem_bytes, dmem_bytes = compile_to_bytes(progname, quiet=quiet)

    def to_mem(raw, mem_path):
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

    to_mem(imem_bytes, build / "inst.mem")
    to_mem(dmem_bytes, build / "data.mem")
    if not quiet:
        print(f"==> build/inst.mem and build/data.mem written ({DRAM_WORDS} words each)")


# ---------------------------------------------------------------------------
# Test runners
# ---------------------------------------------------------------------------

TB = str(ROOT / "build" / "tb_top")


def run_unit_test(name, waves=False):
    waves_flag = ["++waves"] if waves else []

    if name != "all":
        run([TB, "++unit", name, *waves_flag])
        return

    passed = 0
    failed = []
    for unit in UNITS:
        rc, output = run_capture([TB, "++unit", unit, *waves_flag])
        if rc == 0:
            passed += 1
            print(f"{unit}: PASS")
        else:
            failed.append(unit)
            sys.stdout.write(output)
            print(f"{unit}: FAIL")

    total = len(UNITS)
    print(f"\n{passed}/{total} units passed")
    if failed:
        print(f"FAILED: {', '.join(failed)}")


def run_core_test(progname, waves=False):
    waves_flag = ["++waves"] if waves else []
    compile_prog(progname)
    run([TB, "++prog", "++name", progname, *waves_flag])


def run_core_tests_all(waves=False):
    prog_dir = ROOT / "test" / "prog"
    progs = sorted(
        p.stem for p in prog_dir.iterdir()
        if p.is_file() and p.suffix in (".c", ".s")
        and p.stem not in ("util",)
    )
    waves_flag = ["++waves"] if waves else []

    passed = 0
    failed = []
    for name in progs:
        compile_prog(name, quiet=True)
        rc, output = run_capture([TB, "++prog", "++quiet", "++name", name, *waves_flag])
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


# ---------------------------------------------------------------------------
# Dump / clean
# ---------------------------------------------------------------------------

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


def clean():
    import shutil
    for d in [ROOT / "build", SYN_DIR]:
        if d.exists():
            shutil.rmtree(d)
            print(f"==> Removed {d.relative_to(ROOT)}/")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

USAGE = """\
Usage: ./run.py <mode> [options] [name]

Modes:
  ++unit_test [++waves] <unit|all>   Run unit tests (units: dec exe branch fetch icache dcache)
  ++core_test [++waves] <prog|all>   Run core program tests
  ++core_test ++syn                  Synthesize core, then run all program tests
  ++dump <prog>                      Compile prog and write disassembly to build/imem.lst
  ++clean                            Remove build/ and syn/

Options:
  ++waves   Enable VCD waveform output (not valid with ++syn)
"""


def _parse_name(argv):
    for a in argv:
        if not a.startswith("++"):
            return a
    return None


def main():
    argv  = sys.argv[1:]
    flags = set(argv)

    do_unit  = "++unit_test" in flags
    do_core  = "++core_test" in flags
    do_dump  = "++dump"      in flags
    do_clean = "++clean"     in flags
    waves    = "++waves"     in flags
    syn      = "++syn"       in flags

    if do_unit and syn:
        _err("++unit_test cannot be combined with ++syn")
    if do_core and syn and waves:
        _err("++syn and ++waves cannot be combined")

    n_modes = sum([do_unit, do_core, do_dump, do_clean])
    if n_modes != 1:
        print(USAGE)
        sys.exit(1 if n_modes == 0 else 0)

    if do_clean:
        clean()
        return

    name = _parse_name(argv)

    if do_dump:
        if not name:
            _err("++dump requires a program name")
        with _tee_log():
            dump(name)
        return

    with _tee_log():
        if do_unit:
            if not name:
                _err("++unit_test requires a unit name or 'all'")
            build_tb(waves=waves, quiet=(name == "all"))
            run_unit_test(name, waves=waves)

        elif do_core:
            if syn:
                build_tb_syn(quiet=True)
                run_core_tests_all()
            elif name == "all":
                build_tb(waves=waves, quiet=True)
                run_core_tests_all(waves=waves)
            else:
                if not name:
                    _err("++core_test requires a program name or 'all'")
                build_tb(waves=waves, quiet=False)
                run_core_test(name, waves=waves)


if __name__ == "__main__":
    main()
