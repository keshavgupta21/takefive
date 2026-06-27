#include <cstdlib>
#include <iostream>
#include <iomanip>
#include "verilated.h"
#include "ref.h"
#include "dut.h"

static int test_dec(Dut &dut) {
    struct Test {
        const char *name;
        uint32_t pc;
        uint32_t instr;
    };

    static const Test tests[] = {
        // R-type (opcode 0x33)
        {"ADD  x1,x2,x3",    0x00000000, enc_r(0x00,  3,  2, 0,  1, 0x33)},
        {"SUB  x5,x6,x7",    0x00000004, enc_r(0x20,  7,  6, 0,  5, 0x33)},
        {"SLT  x10,x11,x12", 0x00000008, enc_r(0x00, 12, 11, 2, 10, 0x33)},
        {"XOR  x15,x16,x17", 0x0000000C, enc_r(0x00, 17, 16, 4, 15, 0x33)},

        // I-type arithmetic (opcode 0x13)
        {"ADDI x1,x2,100",   0x00000010, enc_i(  100,  2, 0,  1, 0x13)},
        {"ADDI x1,x2,-5",    0x00000014, enc_i(   -5,  2, 0,  1, 0x13)},
        {"ADDI x1,x2,2047",  0x00000018, enc_i( 2047,  2, 0,  1, 0x13)},
        {"ADDI x1,x2,-2048", 0x0000001C, enc_i(-2048,  2, 0,  1, 0x13)},
        {"ANDI x3,x4,0xFF",  0x00000020, enc_i( 0xFF,  4, 7,  3, 0x13)},
        {"SLLI x5,x6,4",     0x00000024, enc_i(    4,  6, 1,  5, 0x13)},

        // I-type load (opcode 0x03)
        {"LW  x1,8(x2)",     0x00000028, enc_i(    8,  2, 2,  1, 0x03)},
        {"LB  x3,0(x4)",     0x0000002C, enc_i(    0,  4, 0,  3, 0x03)},
        {"LH  x5,-4(x6)",    0x00000030, enc_i(   -4,  6, 1,  5, 0x03)},

        // JALR (opcode 0x67)
        {"JALR x1,x2,0",     0x00000034, enc_i(    0,  2, 0,  1, 0x67)},
        {"JALR x0,x1,4",     0x00000038, enc_i(    4,  1, 0,  0, 0x67)},

        // S-type (opcode 0x23)
        {"SW  x1,16(x2)",    0x0000003C, enc_s(   16,  1,  2, 2, 0x23)},
        {"SB  x3,0(x4)",     0x00000040, enc_s(    0,  3,  4, 0, 0x23)},
        {"SH  x5,-8(x6)",    0x00000044, enc_s(   -8,  5,  6, 1, 0x23)},

        // B-type (opcode 0x63)
        {"BEQ  x1,x2,8",     0x00000048, enc_b(    8,  2,  1, 0, 0x63)},
        {"BNE  x3,x4,-16",   0x0000004C, enc_b(  -16,  4,  3, 1, 0x63)},
        {"BLT  x5,x6,256",   0x00000050, enc_b(  256,  6,  5, 4, 0x63)},

        // U-type: LUI (opcode 0x37)
        {"LUI x1,0xDEADB",   0x00000054, enc_u(0xDEADB000,  1, 0x37)},
        {"LUI x2,0x00001",   0x00000058, enc_u(0x00001000,  2, 0x37)},

        // U-type: AUIPC (opcode 0x17)
        {"AUIPC x3,0x12345", 0x0000005C, enc_u(0x12345000,  3, 0x17)},

        // J-type: JAL (opcode 0x6F)
        {"JAL x1,1024",       0x00000060, enc_j( 1024,  1, 0x6F)},
        {"JAL x0,-8",         0x00000064, enc_j(   -8,  0, 0x6F)},

        // Unknown opcode (default -> imm=0)
        {"UNKNOWN",           0xDEADBEEF, 0x0000007B},
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
            std::cerr << "FAIL dec [" << tests[i].name << "]"
                      << "  instr=0x" << std::hex << std::setfill('0')
                      << std::setw(8) << instr << std::dec << "\n"
                      << "  expected: " << ref << "\n"
                      << "  got:      " << got << "\n";
            fail = true;
        }

        if (dut.pc() != pc) {
            std::cerr << "FAIL dec [" << tests[i].name << "] pc passthrough"
                      << "  expected=0x" << std::hex << std::setfill('0')
                      << std::setw(8) << pc
                      << "  got=0x" << std::setw(8) << dut.pc()
                      << std::dec << "\n";
            fail = true;
        }

        if (fail) errors++;
    }

    if (errors == 0)
        std::cout << "dec: PASS (" << n << " tests)" << std::endl;
    else
        std::cout << "dec: FAIL " << errors << " / " << n << std::endl;

    return errors;
}

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    Dut dut;
    int errors = 0;

    errors += test_dec(dut);

    return errors ? EXIT_FAILURE : EXIT_SUCCESS;
}
