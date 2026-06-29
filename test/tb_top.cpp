#include <cstdlib>
#include <cstdint>
#include <iostream>
#include <iomanip>
#include <random>
#include "verilated.h"
#include "ref.h"
#include "dut.h"

static int report(const char *name, int errors, int n) {
    if (errors == 0)
        std::cout << name << ": PASS (" << n << " tests)" << std::endl;
    else
        std::cout << name << ": FAIL " << errors << " / " << n << std::endl;
    return errors;
}

static int test_dec_directed(DecDut &dut) {
    struct Test {
        const char *name;
        uint32_t pc;
        uint32_t instr;
    };

    static const Test tests[] = {
        // ---- Valid R-type (opcode 0x33) ----
        {"ADD  x1,x2,x3",    0x00000000, enc_r(0x00,  3,  2, 0,  1, 0x33)},
        {"SUB  x5,x6,x7",    0x00000004, enc_r(0x20,  7,  6, 0,  5, 0x33)},
        {"SLL  x8,x9,x10",   0x00000008, enc_r(0x00, 10,  9, 1,  8, 0x33)},
        {"SLT  x10,x11,x12", 0x0000000C, enc_r(0x00, 12, 11, 2, 10, 0x33)},
        {"XOR  x15,x16,x17", 0x00000010, enc_r(0x00, 17, 16, 4, 15, 0x33)},
        {"SRL  x1,x2,x3",    0x00000014, enc_r(0x00,  3,  2, 5,  1, 0x33)},
        {"SRA  x1,x2,x3",    0x00000018, enc_r(0x20,  3,  2, 5,  1, 0x33)},
        {"OR   x1,x2,x3",    0x0000001C, enc_r(0x00,  3,  2, 6,  1, 0x33)},
        {"AND  x1,x2,x3",    0x00000020, enc_r(0x00,  3,  2, 7,  1, 0x33)},

        // ---- Invalid R-type ----
        {"R bad f7",          0x00000024, enc_r(0x01,  3,  2, 0,  1, 0x33)},
        {"SLL bad f7",        0x00000028, enc_r(0x20,  3,  2, 1,  1, 0x33)},

        // ---- Valid I-type arithmetic (opcode 0x13) ----
        {"ADDI x1,x2,100",   0x00000030, enc_i(  100,  2, 0,  1, 0x13)},
        {"ADDI x1,x2,-5",    0x00000034, enc_i(   -5,  2, 0,  1, 0x13)},
        {"ADDI x1,x2,2047",  0x00000038, enc_i( 2047,  2, 0,  1, 0x13)},
        {"ADDI x1,x2,-2048", 0x0000003C, enc_i(-2048,  2, 0,  1, 0x13)},
        {"ANDI x3,x4,0xFF",  0x00000040, enc_i( 0xFF,  4, 7,  3, 0x13)},
        {"SLLI x5,x6,4",     0x00000044, enc_i(    4,  6, 1,  5, 0x13)},
        {"SRLI x1,x2,3",     0x00000048, enc_i(    3,  2, 5,  1, 0x13)},
        {"SRAI x1,x2,3",     0x0000004C, enc_r(0x20,  3,  2, 5,  1, 0x13)},

        // ---- Invalid I-type arithmetic ----
        {"SLLI bad f7",       0x00000050, enc_r(0x01,  4,  6, 1,  5, 0x13)},
        {"SRLI bad f7",       0x00000054, enc_r(0x01,  3,  2, 5,  1, 0x13)},

        // ---- Valid I-type load (opcode 0x03) ----
        {"LB  x3,0(x4)",     0x00000060, enc_i(    0,  4, 0,  3, 0x03)},
        {"LH  x5,-4(x6)",    0x00000064, enc_i(   -4,  6, 1,  5, 0x03)},
        {"LW  x1,8(x2)",     0x00000068, enc_i(    8,  2, 2,  1, 0x03)},
        {"LBU x1,0(x2)",     0x0000006C, enc_i(    0,  2, 4,  1, 0x03)},
        {"LHU x1,0(x2)",     0x00000070, enc_i(    0,  2, 5,  1, 0x03)},

        // ---- Invalid loads ----
        {"Load f3=011",       0x00000074, enc_i(    0,  2, 3,  1, 0x03)},
        {"Load f3=110",       0x00000078, enc_i(    0,  2, 6,  1, 0x03)},
        {"Load f3=111",       0x0000007C, enc_i(    0,  2, 7,  1, 0x03)},

        // ---- Valid JALR (opcode 0x67) ----
        {"JALR x1,x2,0",     0x00000080, enc_i(    0,  2, 0,  1, 0x67)},
        {"JALR x0,x1,4",     0x00000084, enc_i(    4,  1, 0,  0, 0x67)},

        // ---- Invalid JALR ----
        {"JALR f3=001",       0x00000088, enc_i(    0,  2, 1,  1, 0x67)},

        // ---- Valid S-type (opcode 0x23) ----
        {"SB  x3,0(x4)",     0x00000090, enc_s(    0,  3,  4, 0, 0x23)},
        {"SH  x5,-8(x6)",    0x00000094, enc_s(   -8,  5,  6, 1, 0x23)},
        {"SW  x1,16(x2)",    0x00000098, enc_s(   16,  1,  2, 2, 0x23)},

        // ---- Invalid stores ----
        {"Store f3=011",      0x0000009C, enc_s(    0,  1,  2, 3, 0x23)},
        {"Store f3=100",      0x000000A0, enc_s(    0,  1,  2, 4, 0x23)},

        // ---- Valid B-type (opcode 0x63) ----
        {"BEQ  x1,x2,8",     0x000000B0, enc_b(    8,  2,  1, 0, 0x63)},
        {"BNE  x3,x4,-16",   0x000000B4, enc_b(  -16,  4,  3, 1, 0x63)},
        {"BLT  x5,x6,256",   0x000000B8, enc_b(  256,  6,  5, 4, 0x63)},
        {"BGE  x1,x2,4",     0x000000BC, enc_b(    4,  2,  1, 5, 0x63)},
        {"BLTU x1,x2,4",     0x000000C0, enc_b(    4,  2,  1, 6, 0x63)},
        {"BGEU x1,x2,4",     0x000000C4, enc_b(    4,  2,  1, 7, 0x63)},

        // ---- Invalid branches ----
        {"Branch f3=010",     0x000000C8, enc_b(    4,  2,  1, 2, 0x63)},
        {"Branch f3=011",     0x000000CC, enc_b(    4,  2,  1, 3, 0x63)},

        // ---- Valid U-type ----
        {"LUI x1,0xDEADB",   0x000000D0, enc_u(0xDEADB000,  1, 0x37)},
        {"LUI x2,0x00001",   0x000000D4, enc_u(0x00001000,  2, 0x37)},
        {"AUIPC x3,0x12345", 0x000000D8, enc_u(0x12345000,  3, 0x17)},

        // ---- Valid J-type ----
        {"JAL x1,1024",       0x000000E0, enc_j( 1024,  1, 0x6F)},
        {"JAL x0,-8",         0x000000E4, enc_j(   -8,  0, 0x6F)},

        // ---- Valid FENCE / SYSTEM ----
        {"FENCE",             0x000000F0, enc_i(0, 0, 0, 0, 0x0F)},
        {"ECALL",             0x000000F4, enc_i(0, 0, 0, 0, 0x73)},
        {"EBREAK",            0x000000F8, enc_i(1, 0, 0, 0, 0x73)},

        // ---- Invalid FENCE / SYSTEM ----
        {"FENCE f3=001",      0x000000FC, enc_i(0, 0, 1, 0, 0x0F)},
        {"SYSTEM f3=001",     0x00000100, enc_i(0, 0, 1, 0, 0x73)},

        // ---- Completely invalid opcode ----
        {"Bad opcode 0x7B",   0xDEADBEEF, 0x0000007B},
    };

    int errors = 0;
    int n = sizeof(tests) / sizeof(tests[0]);

    for (int i = 0; i < n; i++) {
        uint32_t pc    = tests[i].pc;
        uint32_t instr = tests[i].instr;
        Decoded ref = decode(instr);
        Decoded got = dut.decode(pc, instr);

        bool fail = false;

        if (got != ref) {
            std::cerr << "FAIL dec_directed [" << tests[i].name << "]"
                      << "  instr=0x" << std::hex << std::setfill('0')
                      << std::setw(8) << instr << std::dec << "\n"
                      << "  expected: " << ref << "\n"
                      << "  got:      " << got << "\n";
            fail = true;
        }

        if (dut.pc() != pc) {
            std::cerr << "FAIL dec_directed [" << tests[i].name << "] pc passthrough"
                      << "  expected=0x" << std::hex << std::setfill('0')
                      << std::setw(8) << pc
                      << "  got=0x" << std::setw(8) << dut.pc()
                      << std::dec << "\n";
            fail = true;
        }

        if (fail) errors++;
    }

    return report("dec_directed", errors, n);
}

static int test_dec_random(DecDut &dut, int n) {
    std::mt19937 rng(42);
    std::uniform_int_distribution<uint32_t> dist;

    int errors = 0;

    for (int i = 0; i < n; i++) {
        uint32_t pc    = dist(rng) & ~3u;
        uint32_t instr = dist(rng);
        Decoded ref = decode(instr);
        Decoded got = dut.decode(pc, instr);

        bool fail = false;

        if (got != ref) {
            std::cerr << "FAIL dec_random [" << i << "]"
                      << "  instr=0x" << std::hex << std::setfill('0')
                      << std::setw(8) << instr << std::dec << "\n"
                      << "  expected: " << ref << "\n"
                      << "  got:      " << got << "\n";
            fail = true;
        }

        if (dut.pc() != pc) {
            std::cerr << "FAIL dec_random [" << i << "] pc passthrough"
                      << "  expected=0x" << std::hex << std::setfill('0')
                      << std::setw(8) << pc
                      << "  got=0x" << std::setw(8) << dut.pc()
                      << std::dec << "\n";
            fail = true;
        }

        if (fail) errors++;
    }

    return report("dec_random", errors, n);
}

static int test_exe_directed(ExeDut &dut) {
    struct Test {
        const char *name;
        uint32_t pc;
        Decoded  inst;
        uint32_t rval1;
        uint32_t rval2;
        uint32_t dmem_data;
    };

    static const Test tests[] = {
        // ---- R-type ALU (opcode 0x33) ----
        {"ADD",  0x100, make_inst(1, 0x33, 1, 2, 3, 0, 0x00, 0), 0x0000000A, 0x00000014, 0},
        {"SUB",  0x104, make_inst(1, 0x33, 1, 2, 3, 0, 0x20, 0), 0x00000014, 0x0000000A, 0},
        {"SLL",  0x108, make_inst(1, 0x33, 1, 2, 3, 1, 0x00, 0), 0x00000001, 0x00000004, 0},
        {"SLT",  0x10C, make_inst(1, 0x33, 1, 2, 3, 2, 0x00, 0), 0xFFFFFFFF, 0x00000001, 0},
        {"SLTU", 0x110, make_inst(1, 0x33, 1, 2, 3, 3, 0x00, 0), 0x00000001, 0xFFFFFFFF, 0},
        {"XOR",  0x114, make_inst(1, 0x33, 1, 2, 3, 4, 0x00, 0), 0xFF00FF00, 0x0F0F0F0F, 0},
        {"SRL",  0x118, make_inst(1, 0x33, 1, 2, 3, 5, 0x00, 0), 0x80000000, 0x00000004, 0},
        {"SRA",  0x11C, make_inst(1, 0x33, 1, 2, 3, 5, 0x20, 0), 0x80000000, 0x00000004, 0},
        {"OR",   0x120, make_inst(1, 0x33, 1, 2, 3, 6, 0x00, 0), 0xFF00FF00, 0x0F0F0F0F, 0},
        {"AND",  0x124, make_inst(1, 0x33, 1, 2, 3, 7, 0x00, 0), 0xFF00FF00, 0x0F0F0F0F, 0},

        // ---- I-type ALU (opcode 0x13) ----
        {"ADDI",  0x200, make_inst(1, 0x13, 1, 2, 0, 0, 0x00, 100),        0x0000000A, 0, 0},
        {"SLTI",  0x204, make_inst(1, 0x13, 1, 2, 0, 2, 0x00, 0xFFFFFFFF), 0x00000000, 0, 0},
        {"SLTIU", 0x208, make_inst(1, 0x13, 1, 2, 0, 3, 0x00, 0x00000005), 0x00000003, 0, 0},
        {"XORI",  0x20C, make_inst(1, 0x13, 1, 2, 0, 4, 0x00, 0x0000000F), 0xFF00FF00, 0, 0},
        {"ORI",   0x210, make_inst(1, 0x13, 1, 2, 0, 6, 0x00, 0x0000000F), 0xFF00FF00, 0, 0},
        {"ANDI",  0x214, make_inst(1, 0x13, 1, 2, 0, 7, 0x00, 0x0000000F), 0xFF00FF00, 0, 0},
        {"SLLI",  0x218, make_inst(1, 0x13, 1, 2, 0, 1, 0x00, 4),          0x00000001, 0, 0},
        {"SRLI",  0x21C, make_inst(1, 0x13, 1, 2, 0, 5, 0x00, 4),          0x80000000, 0, 0},
        {"SRAI",  0x220, make_inst(1, 0x13, 1, 2, 0, 5, 0x20, 4),          0x80000000, 0, 0},

        // ---- Upper-immediate ----
        {"LUI",   0x300, make_inst(1, 0x37, 1, 0, 0, 0, 0x00, 0xDEADB000), 0, 0, 0},
        {"AUIPC", 0x304, make_inst(1, 0x17, 1, 0, 0, 0, 0x00, 0x12345000), 0, 0, 0},

        // ---- Jumps ----
        {"JAL",   0x400, make_inst(1, 0x6F, 1, 0, 0, 0, 0x00, 1024), 0, 0, 0},
        {"JALR",  0x404, make_inst(1, 0x67, 1, 2, 0, 0, 0x00, 0),    0x00001000, 0, 0},

        // ---- Loads (exe reads dmem_rsp.data) ----
        {"LW",      0x500, make_inst(1, 0x03, 1, 2, 0, 2, 0x00, 8),  0x00001000, 0, 0xDEADBEEF},
        {"LW zero", 0x504, make_inst(1, 0x03, 1, 2, 0, 2, 0x00, 0),  0x00000000, 0, 0x00000000},
        {"LW max",  0x508, make_inst(1, 0x03, 1, 2, 0, 2, 0x00, 4),  0x00000100, 0, 0xFFFFFFFF},

        // ---- No-writeback (exe ignores these) ----
        {"SW",    0x600, make_inst(1, 0x23, 0, 2, 3, 2, 0x00, 16), 0x00001000, 0xAAAAAAAA, 0},
        {"BEQ",   0x604, make_inst(1, 0x63, 0, 1, 2, 0, 0x00, 8),  0x00000005, 0x00000005, 0},
        {"FENCE", 0x608, make_inst(1, 0x0F, 0, 0, 0, 0, 0x00, 0),  0, 0, 0},
        {"ECALL", 0x60C, make_inst(1, 0x73, 0, 0, 0, 0, 0x00, 0),  0, 0, 0},

        // ---- Invalid ----
        {"Invalid", 0x700, make_inst(0, 0x33, 1, 2, 3, 0, 0x00, 0), 0x0000000A, 0x00000014, 0},
    };

    int errors = 0;
    int n = sizeof(tests) / sizeof(tests[0]);

    for (int i = 0; i < n; i++) {
        dut.eval(tests[i].pc, tests[i].inst, tests[i].rval1, tests[i].rval2,
                 tests[i].dmem_data);
        ExeResult ref = execute(tests[i].pc, tests[i].inst,
                                tests[i].rval1, tests[i].rval2, tests[i].dmem_data);
        ExeResult got = dut.result();

        if (got != ref) {
            std::cerr << "FAIL exe_directed [" << tests[i].name << "]"
                      << "  pc=0x" << std::hex << std::setfill('0')
                      << std::setw(8) << tests[i].pc << std::dec << "\n"
                      << "  expected: " << ref << "\n"
                      << "  got:      " << got << "\n";
            errors++;
        }
    }

    return report("exe_directed", errors, n);
}

static int test_exe_random(ExeDut &dut, int n) {
    std::mt19937 rng(77);
    std::uniform_int_distribution<uint32_t> val_dist;

    int errors = 0;

    for (int i = 0; i < n; i++) {
        Decoded inst = gen_random_inst(rng);

        uint32_t pc        = val_dist(rng) & ~3u;
        uint32_t rval1     = val_dist(rng);
        uint32_t rval2     = val_dist(rng);
        uint32_t dmem_data = val_dist(rng);

        dut.eval(pc, inst, rval1, rval2, dmem_data);
        ExeResult ref = execute(pc, inst, rval1, rval2, dmem_data);
        ExeResult got = dut.result();

        if (got != ref) {
            std::cerr << "FAIL exe_random [" << i << "]"
                      << "  pc=0x" << std::hex << std::setfill('0')
                      << std::setw(8) << pc << std::dec << "\n"
                      << "  decoded:  " << inst << "\n"
                      << "  expected: " << ref << "\n"
                      << "  got:      " << got << "\n";
            errors++;
        }
    }

    return report("exe_random", errors, n);
}

static int test_mem_directed(MemDut &dut) {
    struct Test {
        const char *name;
        Decoded  inst;
        uint32_t rval1;
        uint32_t rval2;
    };

    static const Test tests[] = {
        // ---- LW ----
        {"LW base+0",    make_inst(1, 0x03, 1, 2, 0, 2, 0x00, 0),    0x00001000, 0},
        {"LW base+imm",  make_inst(1, 0x03, 1, 2, 0, 2, 0x00, 100),  0x00000800, 0},
        {"LW neg imm",   make_inst(1, 0x03, 1, 2, 0, 2, 0x00, 0xFFFFFFFC), 0x00000100, 0},

        // ---- SW ----
        {"SW base+0",    make_inst(1, 0x23, 0, 2, 3, 2, 0x00, 0),    0x00002000, 0xDEADBEEF},
        {"SW base+imm",  make_inst(1, 0x23, 0, 2, 3, 2, 0x00, 200),  0x00000400, 0xCAFEBABE},
        {"SW neg imm",   make_inst(1, 0x23, 0, 2, 3, 2, 0x00, 0xFFFFFFF0), 0x00000100, 0x12345678},

        // ---- Non-memory opcodes ----
        {"ADD no req",   make_inst(1, 0x33, 1, 2, 3, 0, 0x00, 0),    0x0000000A, 0x00000014},
        {"LUI no req",   make_inst(1, 0x37, 1, 0, 0, 0, 0x00, 0xDEADB000), 0, 0},
        {"BEQ no req",   make_inst(1, 0x63, 0, 1, 2, 0, 0x00, 8),    0x00000005, 0x00000005},
        {"JAL no req",   make_inst(1, 0x6F, 1, 0, 0, 0, 0x00, 1024), 0, 0},

        // ---- Invalid instruction ----
        {"Invalid",      make_inst(0, 0x03, 1, 2, 0, 2, 0x00, 0),    0x00001000, 0},
    };

    int errors = 0;
    int n = sizeof(tests) / sizeof(tests[0]);

    for (int i = 0; i < n; i++) {
        dut.eval(tests[i].inst, tests[i].rval1, tests[i].rval2);
        MemReqResult ref = mem_eval(tests[i].inst, tests[i].rval1, tests[i].rval2);
        MemReqResult got = dut.result();

        if (got != ref) {
            std::cerr << "FAIL mem_directed [" << tests[i].name << "]\n"
                      << "  expected: " << ref << "\n"
                      << "  got:      " << got << "\n";
            errors++;
        }
    }

    return report("mem_directed", errors, n);
}

static int test_branch_directed(BranchDut &dut) {
    struct Test {
        const char *name;
        uint32_t pc;
        Decoded  inst;
        uint32_t rval1;
        uint32_t rval2;
    };

    static const Test tests[] = {
        // ---- BEQ ----
        {"BEQ taken",     0x100, make_inst(1, 0x63, 0, 1, 2, 0, 0x00, 8),
         0x12345678, 0x12345678},
        {"BEQ not taken", 0x104, make_inst(1, 0x63, 0, 1, 2, 0, 0x00, 8),
         0x12345678, 0x87654321},

        // ---- BNE ----
        {"BNE taken",     0x200, make_inst(1, 0x63, 0, 1, 2, 1, 0x00, 16),
         0x00000001, 0x00000002},
        {"BNE not taken", 0x204, make_inst(1, 0x63, 0, 1, 2, 1, 0x00, 16),
         0x0000FFFF, 0x0000FFFF},

        // ---- BLT (signed) ----
        {"BLT taken",     0x300, make_inst(1, 0x63, 0, 1, 2, 4, 0x00, 32),
         0xFFFFFFFF, 0x00000001},
        {"BLT not taken", 0x304, make_inst(1, 0x63, 0, 1, 2, 4, 0x00, 32),
         0x00000001, 0xFFFFFFFF},
        {"BLT equal",     0x308, make_inst(1, 0x63, 0, 1, 2, 4, 0x00, 32),
         0x00000005, 0x00000005},

        // ---- BGE (signed) ----
        {"BGE taken >=",  0x400, make_inst(1, 0x63, 0, 1, 2, 5, 0x00, 64),
         0x00000001, 0xFFFFFFFF},
        {"BGE taken ==",  0x404, make_inst(1, 0x63, 0, 1, 2, 5, 0x00, 64),
         0x00000005, 0x00000005},
        {"BGE not taken", 0x408, make_inst(1, 0x63, 0, 1, 2, 5, 0x00, 64),
         0xFFFFFFFF, 0x00000001},

        // ---- BLTU (unsigned) ----
        {"BLTU taken",     0x500, make_inst(1, 0x63, 0, 1, 2, 6, 0x00, 128),
         0x00000001, 0xFFFFFFFF},
        {"BLTU not taken", 0x504, make_inst(1, 0x63, 0, 1, 2, 6, 0x00, 128),
         0xFFFFFFFF, 0x00000001},

        // ---- BGEU (unsigned) ----
        {"BGEU taken >=",  0x600, make_inst(1, 0x63, 0, 1, 2, 7, 0x00, 256),
         0xFFFFFFFF, 0x00000001},
        {"BGEU taken ==",  0x604, make_inst(1, 0x63, 0, 1, 2, 7, 0x00, 256),
         0x80000000, 0x80000000},
        {"BGEU not taken", 0x608, make_inst(1, 0x63, 0, 1, 2, 7, 0x00, 256),
         0x00000001, 0xFFFFFFFF},

        // ---- BEQ negative offset ----
        {"BEQ neg offset", 0x200, make_inst(1, 0x63, 0, 1, 2, 0, 0x00, 0xFFFFFFF0),
         0x00000042, 0x00000042},

        // ---- JAL ----
        {"JAL +1024",      0x400, make_inst(1, 0x6F, 1, 0, 0, 0, 0x00, 1024),
         0, 0},
        {"JAL -8",         0x800, make_inst(1, 0x6F, 0, 0, 0, 0, 0x00, 0xFFFFFFF8),
         0, 0},

        // ---- JALR ----
        {"JALR base+imm", 0x100, make_inst(1, 0x67, 1, 2, 0, 0, 0x00, 100),
         0x00001000, 0},
        {"JALR LSB clear", 0x100, make_inst(1, 0x67, 1, 2, 0, 0, 0x00, 1),
         0x00000003, 0},

        // ---- Non-branch opcodes (should produce vld=0) ----
        {"ADD no redir",  0x100, make_inst(1, 0x33, 1, 2, 3, 0, 0x00, 0),
         0x0000000A, 0x00000014},
        {"LUI no redir",  0x300, make_inst(1, 0x37, 1, 0, 0, 0, 0x00, 0xDEADB000),
         0, 0},
        {"ADDI no redir", 0x200, make_inst(1, 0x13, 1, 2, 0, 0, 0x00, 100),
         0x0000000A, 0},

        // ---- Invalid instruction ----
        {"Invalid",       0x600, make_inst(0, 0x63, 0, 1, 2, 0, 0x00, 8),
         0x12345678, 0x12345678},
    };

    int errors = 0;
    int n = sizeof(tests) / sizeof(tests[0]);

    for (int i = 0; i < n; i++) {
        dut.eval(tests[i].pc, tests[i].inst, tests[i].rval1, tests[i].rval2);
        NxtPcResult ref = branch_eval(tests[i].pc, tests[i].inst,
                                      tests[i].rval1, tests[i].rval2);
        NxtPcResult got = dut.result();

        if (got != ref) {
            std::cerr << "FAIL branch_directed [" << tests[i].name << "]"
                      << "  pc=0x" << std::hex << std::setfill('0')
                      << std::setw(8) << tests[i].pc << std::dec << "\n"
                      << "  expected: " << ref << "\n"
                      << "  got:      " << got << "\n";
            errors++;
        }
    }

    return report("branch_directed", errors, n);
}

static int test_fetch_random(FetchDut &dut, int n_rounds) {
    const int depth = 64;
    std::mt19937 rng(55);
    std::uniform_int_distribution<uint32_t> val_dist;
    std::uniform_int_distribution<int> len_dist(32, 64);
    std::bernoulli_distribution redirect_dist(0.1);

    FetchRef ref(depth);
    int errors = 0;

    for (int r = 0; r < n_rounds; r++) {
        int n = len_dist(rng);

        dut.set_nxt_pc(false, 0, 0);
        dut.set_rst(true);
        dut.tick();

        for (int i = 0; i < n; i++) {
            uint32_t inst = val_dist(rng);
            ref.write(i * 4, inst);
            dut.write(i * 4, inst);
            dut.tick();
        }

        dut.clear_write();
        dut.set_nxt_pc(false, 0, 0);
        dut.tick();
        dut.set_rst(false);
        ref.reset();

        for (int i = 0; i < n;) {
            if (!dut.f_vld()) {
                dut.tick();
                continue;
            }

            uint32_t exp_pc   = ref.pc();
            uint32_t exp_inst = ref.inst();
            uint32_t got_pc   = dut.f_pc();
            uint32_t got_inst = dut.f_inst();

            if (got_pc != exp_pc || got_inst != exp_inst) {
                std::cerr << "FAIL fetch_random [round=" << r
                          << " cycle=" << i << "]"
                          << "  expected pc=0x" << std::hex << std::setfill('0')
                          << std::setw(8) << exp_pc
                          << " inst=0x" << std::setw(8) << exp_inst
                          << "  got pc=0x" << std::setw(8) << got_pc
                          << " inst=0x" << std::setw(8) << got_inst
                          << std::dec << "\n";
                errors++;
                return report("fetch_random", errors, r + 1);
            }

            bool do_redirect = redirect_dist(rng);
            uint32_t target  = (val_dist(rng) % n) * 4;
            dut.set_nxt_pc(do_redirect, 0, target);
            dut.tick();
            ref.tick(do_redirect, target);
            dut.set_nxt_pc(false, 0, 0);
            i++;
        }
    }

    return report("fetch_random", errors, n_rounds);
}

static void dump_pc_trace(const std::vector<uint32_t> &pcs,
                          const std::vector<uint32_t> &prog, int depth) {
    uint32_t addr_mask = (depth * 4) - 1;
    std::cerr << "--- Expected PC trace (" << pcs.size() << " instructions) ---\n";
    for (size_t i = 0; i < pcs.size(); i++) {
        uint32_t eff = pcs[i] & addr_mask;
        int word_idx = eff / 4;
        Decoded d = decode(prog[word_idx]);
        std::cerr << "  [" << i << "] pc=0x" << std::hex << std::setfill('0')
                  << std::setw(8) << pcs[i]
                  << " eff=0x" << std::setw(4) << eff
                  << "  " << std::dec << disasm(d) << "\n";
    }
    std::cerr << "---\n";
}

static void dump_program(const std::vector<uint32_t> &prog, int depth) {
    std::cerr << "--- Program (" << depth << " instructions) ---\n";
    for (int i = 0; i < depth; i++) {
        Decoded d = decode(prog[i]);
        std::cerr << "  0x" << std::hex << std::setfill('0') << std::setw(4)
                  << (i * 4) << ": "
                  << std::setw(8) << prog[i] << "  "
                  << std::dec << disasm(d) << "\n";
    }
    std::cerr << "---\n";
}

static int test_core_random(CoreDut &dut, const char *name, int n_rounds,
                            int hazard_dist, bool no_branches,
                            bool short_prog = false, bool no_mem = false) {
    const int depth = 1024;
    std::mt19937 rng(200);
    std::uniform_int_distribution<int> len_dist(short_prog ? 5 : 32,
                                                short_prog ? 10 : 1024);

    CoreRef ref(depth);
    CoreRef::Stats total = {};
    uint64_t total_hw_cycles = 0;
    std::uniform_int_distribution<uint32_t> val_dist;
    std::vector<uint32_t> prog(depth);

    for (int r = 0; r < n_rounds; r++) {
        waves_reset();
        int n = len_dist(rng);

        dut.set_rst(true);
        dut.tick();
        dut.set_pause(true);

        for (int i = 0; i < depth; i++) {
            prog[i] = pack(gen_random_inst(rng, hazard_dist, no_branches, no_mem));
            ref.write_imem(i * 4, prog[i]);
            dut.write(i * 4, prog[i]);
            dut.write_dmem(i * 4, 0);
            dut.tick();
        }

        for (int i = 1; i < 32; i++) {
            uint32_t val = val_dist(rng);
            ref.write_reg(i, val);
            dut.write_reg(i, val);
            dut.tick();
        }

        dut.set_pause(false);
        dut.tick();
        dut.set_rst(false);
        ref.reset();

        std::vector<uint32_t> ref_pcs(n);
        for (int i = 0; i < n; i++) {
            ref_pcs[i] = ref.pc();
            ref.tick();
        }

        int retired = 0;
        int hw_cycles = 0;
        bool timed_out = false;
        for (; retired < n; hw_cycles++) {
            if (hw_cycles >= n * 100) {
                std::cerr << "FAIL " << name << " [round=" << r
                          << "] timeout: retired " << retired
                          << " / " << n << " after " << hw_cycles
                          << " cycles\n";
                timed_out = true;
                break;
            }
            dut.tick();
            dut.eval();
            if (dut.commit()) retired++;
        }

        if (timed_out) {
            dump_pc_trace(ref_pcs, prog, depth);
            dump_program(prog, depth);
            return report(name, 1, r + 1);
        }

        dut.set_pause(true);
        dut.eval();

        bool round_fail = false;

        for (int i = 0; i < 32; i++) {
            uint32_t exp = ref.read_reg(i);
            uint32_t got = dut.read_reg(i);
            if (got != exp) {
                std::cerr << "FAIL " << name << " [round=" << r
                          << " n=" << n << "] x" << i
                          << "  expected=0x" << std::hex << std::setfill('0')
                          << std::setw(8) << exp
                          << "  got=0x" << std::setw(8) << got
                          << std::dec << "\n";
                round_fail = true;
            }
        }

        if (round_fail) {
            dump_pc_trace(ref_pcs, prog, depth);
            dump_program(prog, depth);
            return report(name, 1, r + 1);
        }

        total_hw_cycles          += hw_cycles;
        auto &s = ref.stats();
        total.cycles             += s.cycles;
        total.valid              += s.valid;
        total.alu                += s.alu;
        total.branches_taken     += s.branches_taken;
        total.branches_not_taken += s.branches_not_taken;
        total.jumps              += s.jumps;
        total.lui_auipc          += s.lui_auipc;
        total.loads              += s.loads;
        total.stores             += s.stores;
        total.rf_writes          += s.rf_writes;
    }

    int rc = report(name, 0, n_rounds);
    double cpi = total.valid ? (double)total_hw_cycles / total.valid : 0.0;
    std::cout << "  instructions:        " << total.valid << "\n"
              << "  hw_cycles:           " << total_hw_cycles << "\n"
              << "  CPI:                 " << std::fixed << std::setprecision(2) << cpi << "\n"
              << "  alu:                 " << total.alu << "\n"
              << "  branches_taken:      " << total.branches_taken << "\n"
              << "  branches_not_taken:  " << total.branches_not_taken << "\n"
              << "  jumps:               " << total.jumps << "\n"
              << "  lui_auipc:           " << total.lui_auipc << "\n"
              << "  loads:               " << total.loads << "\n"
              << "  stores:              " << total.stores << "\n"
              << "  rf_writes:           " << total.rf_writes << "\n";
    return rc;
}

static int test_icache_random(ICacheDut &dut, int n) {
    const int DEPTH = 1024;
    const int TOTAL = DEPTH;

    std::mt19937 rng(99);
    std::uniform_int_distribution<uint32_t> val_dist;
    std::uniform_int_distribution<int> addr_dist(0, TOTAL - 1);
    std::uniform_int_distribution<int> pct_dist(0, 99);

    int errors = 0;
    std::vector<uint32_t> ref_mem(TOTAL);

    dut.set_rst(true);
    dut.tick();

    for (int i = 0; i < TOTAL; i++) {
        ref_mem[i] = val_dist(rng);
        dut.write(i * 4, ref_mem[i]);
        dut.tick();
    }

    dut.clear_write();
    dut.tick();
    dut.set_rst(false);
    dut.tick();

    int word_idx = addr_dist(rng);
    uint64_t total_cycles = 0;

    for (int i = 0; i < n; i++) {
        dut.set_req(word_idx * 4);

        uint64_t req_cycles = 0;
        do { dut.tick(); req_cycles++; } while (!dut.rsp_vld());
        total_cycles += req_cycles;

        if (dut.rsp_data() != ref_mem[word_idx]) {
            if (errors < 10)
                std::cerr << "FAIL cache_random [" << i
                          << "] addr=0x" << std::hex << std::setfill('0')
                          << std::setw(8) << (word_idx * 4)
                          << "  expected=0x" << std::setw(8) << ref_mem[word_idx]
                          << "  got=0x" << std::setw(8) << dut.rsp_data()
                          << std::dec << "\n";
            errors++;
        }

        if (pct_dist(rng) < 99) word_idx = (word_idx + 1) % TOTAL;
        else                     word_idx = addr_dist(rng);
    }

    int rc = report("icache_random", errors, n);
    double cpi = n ? (double)total_cycles / n : 0.0;
    std::cout << "  CPI:                 " << std::fixed << std::setprecision(2) << cpi << "\n";
    return rc;
}

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    bool syn = false;
    bool waves = false;
    for (int i = 1; i < argc; i++) {
        if (std::string(argv[i]) == "++syn")   syn   = true;
        if (std::string(argv[i]) == "++waves") waves = true;
    }

#ifdef WAVES
    if (waves) waves_init();
#endif

    int errors = 0;

    DecDut dec_dut;
    ExeDut exe_dut;
    MemDut mem_dut;
    BranchDut branch_dut;
    FetchDut fetch_dut;
    CoreDut core_dut;
    ICacheDut icache_dut;

#ifdef WAVES
    if (waves) waves_open("build/waves.vcd");
#endif

    waves_reset(); errors += test_dec_directed(dec_dut);
    waves_reset(); errors += test_dec_random(dec_dut, syn ? 100 : 10000000);
    waves_reset(); errors += test_exe_directed(exe_dut);
    waves_reset(); errors += test_exe_random(exe_dut, syn ? 100 : 1000000);
    waves_reset(); errors += test_mem_directed(mem_dut);
    waves_reset(); errors += test_branch_directed(branch_dut);
    waves_reset(); errors += test_fetch_random(fetch_dut, syn ? 100 : 10000);
    waves_reset(); errors += test_icache_random(icache_dut, syn ? 1000 : 1000000);
    waves_reset(); errors += test_core_random(core_dut, "core_alu_only",        syn ? 100 : 10000, 3, true,  true,  true);
    waves_reset(); errors += test_core_random(core_dut, "core_short_no_branch", syn ? 100 : 10000, 3, true,  true,  false);
    waves_reset(); errors += test_core_random(core_dut, "core_short_no_hazard", syn ? 100 : 10000, 3, false, true,  false);
    waves_reset(); errors += test_core_random(core_dut, "core_short_random",    syn ? 100 : 10000, 0, false, true,  false);
    waves_reset(); errors += test_core_random(core_dut, "core_no_branch",       syn ? 100 : 10000, 3, true,  false, false);
    waves_reset(); errors += test_core_random(core_dut, "core_no_hazard",       syn ? 100 : 10000, 3, false, false, false);
    waves_reset(); errors += test_core_random(core_dut, "core_random",          syn ? 100 : 10000, 0, false, false, false);

#ifdef WAVES
    if (waves) waves_close();
#endif

    return errors ? EXIT_FAILURE : EXIT_SUCCESS;
}
