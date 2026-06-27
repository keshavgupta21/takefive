#include <cstdlib>
#include <cstdint>
#include <iostream>
#include <iomanip>
#include <random>
#include "verilated.h"
#include "ref.h"
#include "dut.h"

static int test_dec_directed(Dut &dut) {
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

    if (errors == 0)
        std::cout << "dec_directed: PASS (" << n << " tests)" << std::endl;
    else
        std::cout << "dec_directed: FAIL " << errors << " / " << n << std::endl;

    return errors;
}

static int test_dec_random(Dut &dut, int n) {
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

    if (errors == 0)
        std::cout << "dec_random: PASS (" << n << " tests)" << std::endl;
    else
        std::cout << "dec_random: FAIL " << errors << " / " << n << std::endl;

    return errors;
}

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    Dut dut;
    int errors = 0;

    errors += test_dec_directed(dut);
    errors += test_dec_random(dut, 10000000);

    return errors ? EXIT_FAILURE : EXIT_SUCCESS;
}
