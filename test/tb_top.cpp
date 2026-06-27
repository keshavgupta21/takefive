#include <cstdlib>
#include <cstdint>
#include <iostream>
#include <iomanip>
#include <random>
#include "verilated.h"
#include "ref.h"
#include "dut.h"

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

    if (errors == 0)
        std::cout << "dec_directed: PASS (" << n << " tests)" << std::endl;
    else
        std::cout << "dec_directed: FAIL " << errors << " / " << n << std::endl;

    return errors;
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

    if (errors == 0)
        std::cout << "dec_random: PASS (" << n << " tests)" << std::endl;
    else
        std::cout << "dec_random: FAIL " << errors << " / " << n << std::endl;

    return errors;
}

static int check_rf(RfDut &dut, RfRef &ref, const char *name,
                    uint8_t rs1, uint8_t rs2, int &errors) {
    dut.set_read(rs1, rs2);
    uint32_t exp1 = ref.read(rs1), exp2 = ref.read(rs2);
    uint32_t got1 = dut.rval1(),   got2 = dut.rval2();
    bool fail = false;

    if (got1 != exp1) {
        std::cerr << "FAIL rf [" << name << "] rval1"
                  << " rs1=" << (int)rs1
                  << " expected=0x" << std::hex << std::setfill('0')
                  << std::setw(8) << exp1
                  << " got=0x" << std::setw(8) << got1
                  << std::dec << "\n";
        fail = true;
    }
    if (got2 != exp2) {
        std::cerr << "FAIL rf [" << name << "] rval2"
                  << " rs2=" << (int)rs2
                  << " expected=0x" << std::hex << std::setfill('0')
                  << std::setw(8) << exp2
                  << " got=0x" << std::setw(8) << got2
                  << std::dec << "\n";
        fail = true;
    }
    if (fail) errors++;
    return fail ? 1 : 0;
}

static int test_rf_directed(RfDut &dut) {
    RfRef ref;
    int errors = 0;
    int n = 0;

    // x0 reads as zero without any writes
    check_rf(dut, ref, "x0 initial", 0, 0, errors); n++;

    // Initialize all registers to known values
    for (int i = 1; i < 32; i++) {
        uint32_t val = 0x100 * i + i;
        ref.write(i, true, val);
        dut.set_write(i, true, val);
        dut.tick();
    }

    // Read back all pairs
    for (int i = 0; i < 32; i++) {
        int j = 31 - i;
        char name[32];
        snprintf(name, sizeof(name), "readback x%d,x%d", i, j);
        check_rf(dut, ref, name, i, j, errors); n++;
    }

    // Write x0 should be ignored
    ref.write(0, true, 0x12345678);
    dut.set_write(0, true, 0x12345678);
    dut.tick();
    check_rf(dut, ref, "write x0 ignored", 0, 1, errors); n++;

    // Write with wen=0 should not write
    ref.write(2, false, 0xAAAAAAAA);
    dut.set_write(2, false, 0xAAAAAAAA);
    dut.tick();
    check_rf(dut, ref, "wen=0 no write", 2, 0, errors); n++;

    // Overwrite x1 and verify old value replaced
    ref.write(1, true, 0xCAFEBABE);
    dut.set_write(1, true, 0xCAFEBABE);
    dut.tick();
    check_rf(dut, ref, "overwrite x1", 1, 1, errors); n++;

    if (errors == 0)
        std::cout << "rf_directed: PASS (" << n << " tests)" << std::endl;
    else
        std::cout << "rf_directed: FAIL " << errors << " / " << n << std::endl;

    return errors;
}

static int test_rf_random(RfDut &dut, int n) {
    std::mt19937 rng(99);
    std::uniform_int_distribution<uint32_t> val_dist;
    std::uniform_int_distribution<uint8_t>  reg_dist(0, 31);
    std::bernoulli_distribution coin(0.5);

    RfRef ref;
    int errors = 0;

    // Initialize all registers so ref and DUT agree
    for (int i = 1; i < 32; i++) {
        uint32_t val = val_dist(rng);
        ref.write(i, true, val);
        dut.set_write(i, true, val);
        dut.tick();
    }

    for (int i = 0; i < n; i++) {
        if (coin(rng)) {
            bool wen = coin(rng);
            uint8_t rd = reg_dist(rng);
            uint32_t wdata = val_dist(rng);
            ref.write(rd, wen, wdata);
            dut.set_write(rd, wen, wdata);
            dut.tick();
        }

        if (coin(rng)) {
            uint8_t rs1 = reg_dist(rng);
            dut.set_read(rs1, 0);
            if (dut.rval1() != ref.read(rs1)) {
                std::cerr << "FAIL rf_random [" << i << "] rval1"
                          << " rs1=" << (int)rs1
                          << " expected=0x" << std::hex << std::setfill('0')
                          << std::setw(8) << ref.read(rs1)
                          << " got=0x" << std::setw(8) << dut.rval1()
                          << std::dec << "\n";
                errors++;
            }
        }

        if (coin(rng)) {
            uint8_t rs2 = reg_dist(rng);
            dut.set_read(0, rs2);
            if (dut.rval2() != ref.read(rs2)) {
                std::cerr << "FAIL rf_random [" << i << "] rval2"
                          << " rs2=" << (int)rs2
                          << " expected=0x" << std::hex << std::setfill('0')
                          << std::setw(8) << ref.read(rs2)
                          << " got=0x" << std::setw(8) << dut.rval2()
                          << std::dec << "\n";
                errors++;
            }
        }
    }

    if (errors == 0)
        std::cout << "rf_random: PASS (" << n << " tests)" << std::endl;
    else
        std::cout << "rf_random: FAIL " << errors << " / " << n << std::endl;

    return errors;
}

static Decoded make_inst(bool vld, uint8_t opc, uint8_t rd, uint8_t rs1,
                         uint8_t rs2, uint8_t f3, uint8_t f7, uint32_t imm) {
    Decoded d;
    d.vld    = vld;
    d.opcode = opc;
    d.rd     = rd;
    d.rs1    = rs1;
    d.rs2    = rs2;
    d.funct3 = f3;
    d.funct7 = f7;
    d.imm    = imm;
    return d;
}

static int test_exe_directed(ExeDut &dut) {
    struct Test {
        const char *name;
        uint32_t pc;
        Decoded  inst;
        uint32_t rval1;
        uint32_t rval2;
    };

    static const Test tests[] = {
        // ---- R-type ALU (opcode 0x33) ----
        {"ADD",  0x100, make_inst(1, 0x33, 1, 2, 3, 0, 0x00, 0), 0x0000000A, 0x00000014},
        {"SUB",  0x104, make_inst(1, 0x33, 1, 2, 3, 0, 0x20, 0), 0x00000014, 0x0000000A},
        {"SLL",  0x108, make_inst(1, 0x33, 1, 2, 3, 1, 0x00, 0), 0x00000001, 0x00000004},
        {"SLT",  0x10C, make_inst(1, 0x33, 1, 2, 3, 2, 0x00, 0), 0xFFFFFFFF, 0x00000001},
        {"SLTU", 0x110, make_inst(1, 0x33, 1, 2, 3, 3, 0x00, 0), 0x00000001, 0xFFFFFFFF},
        {"XOR",  0x114, make_inst(1, 0x33, 1, 2, 3, 4, 0x00, 0), 0xFF00FF00, 0x0F0F0F0F},
        {"SRL",  0x118, make_inst(1, 0x33, 1, 2, 3, 5, 0x00, 0), 0x80000000, 0x00000004},
        {"SRA",  0x11C, make_inst(1, 0x33, 1, 2, 3, 5, 0x20, 0), 0x80000000, 0x00000004},
        {"OR",   0x120, make_inst(1, 0x33, 1, 2, 3, 6, 0x00, 0), 0xFF00FF00, 0x0F0F0F0F},
        {"AND",  0x124, make_inst(1, 0x33, 1, 2, 3, 7, 0x00, 0), 0xFF00FF00, 0x0F0F0F0F},

        // ---- I-type ALU (opcode 0x13) ----
        {"ADDI",  0x200, make_inst(1, 0x13, 1, 2, 0, 0, 0x00, 100),        0x0000000A, 0},
        {"SLTI",  0x204, make_inst(1, 0x13, 1, 2, 0, 2, 0x00, 0xFFFFFFFF), 0x00000000, 0},
        {"SLTIU", 0x208, make_inst(1, 0x13, 1, 2, 0, 3, 0x00, 0x00000005), 0x00000003, 0},
        {"XORI",  0x20C, make_inst(1, 0x13, 1, 2, 0, 4, 0x00, 0x0000000F), 0xFF00FF00, 0},
        {"ORI",   0x210, make_inst(1, 0x13, 1, 2, 0, 6, 0x00, 0x0000000F), 0xFF00FF00, 0},
        {"ANDI",  0x214, make_inst(1, 0x13, 1, 2, 0, 7, 0x00, 0x0000000F), 0xFF00FF00, 0},
        {"SLLI",  0x218, make_inst(1, 0x13, 1, 2, 0, 1, 0x00, 4),          0x00000001, 0},
        {"SRLI",  0x21C, make_inst(1, 0x13, 1, 2, 0, 5, 0x00, 4),          0x80000000, 0},
        {"SRAI",  0x220, make_inst(1, 0x13, 1, 2, 0, 5, 0x20, 4),          0x80000000, 0},

        // ---- Upper-immediate ----
        {"LUI",   0x300, make_inst(1, 0x37, 1, 0, 0, 0, 0x00, 0xDEADB000), 0, 0},
        {"AUIPC", 0x304, make_inst(1, 0x17, 1, 0, 0, 0, 0x00, 0x12345000), 0, 0},

        // ---- Jumps ----
        {"JAL",   0x400, make_inst(1, 0x6F, 1, 0, 0, 0, 0x00, 1024), 0, 0},
        {"JALR",  0x404, make_inst(1, 0x67, 1, 2, 0, 0, 0x00, 0),    0x00001000, 0},

        // ---- No-writeback (exe ignores these) ----
        {"LW",    0x500, make_inst(1, 0x03, 1, 2, 0, 2, 0x00, 8),  0x00001000, 0},
        {"SW",    0x504, make_inst(1, 0x23, 0, 2, 3, 2, 0x00, 16), 0x00001000, 0xAAAAAAAA},
        {"BEQ",   0x508, make_inst(1, 0x63, 0, 1, 2, 0, 0x00, 8),  0x00000005, 0x00000005},
        {"FENCE", 0x50C, make_inst(1, 0x0F, 0, 0, 0, 0, 0x00, 0),  0, 0},
        {"ECALL", 0x510, make_inst(1, 0x73, 0, 0, 0, 0, 0x00, 0),  0, 0},

        // ---- Invalid ----
        {"Invalid", 0x600, make_inst(0, 0x33, 1, 2, 3, 0, 0x00, 0), 0x0000000A, 0x00000014},
    };

    int errors = 0;
    int n = sizeof(tests) / sizeof(tests[0]);

    for (int i = 0; i < n; i++) {
        dut.eval(tests[i].pc, tests[i].inst, tests[i].rval1, tests[i].rval2);
        ExeResult ref = execute(tests[i].pc, tests[i].inst,
                                tests[i].rval1, tests[i].rval2);
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

    if (errors == 0)
        std::cout << "exe_directed: PASS (" << n << " tests)" << std::endl;
    else
        std::cout << "exe_directed: FAIL " << errors << " / " << n << std::endl;

    return errors;
}

static int test_exe_random(ExeDut &dut, int n) {
    struct InstType { uint8_t opc; uint8_t f3; uint8_t f7; };
    static const InstType types[] = {
        {0x33, 0, 0x00}, {0x33, 0, 0x20}, {0x33, 1, 0x00}, {0x33, 2, 0x00},
        {0x33, 3, 0x00}, {0x33, 4, 0x00}, {0x33, 5, 0x00}, {0x33, 5, 0x20},
        {0x33, 6, 0x00}, {0x33, 7, 0x00},
        {0x13, 0, 0x00}, {0x13, 2, 0x00}, {0x13, 3, 0x00}, {0x13, 4, 0x00},
        {0x13, 6, 0x00}, {0x13, 7, 0x00}, {0x13, 1, 0x00}, {0x13, 5, 0x00},
        {0x13, 5, 0x20},
        {0x37, 0, 0x00}, {0x17, 0, 0x00},
        {0x6F, 0, 0x00}, {0x67, 0, 0x00},
    };
    static const int ntypes = sizeof(types) / sizeof(types[0]);

    std::mt19937 rng(77);
    std::uniform_int_distribution<uint32_t> val_dist;
    std::uniform_int_distribution<int>      type_dist(0, ntypes - 1);
    std::uniform_int_distribution<uint8_t>  reg_dist(0, 31);

    int errors = 0;

    for (int i = 0; i < n; i++) {
        const InstType &t = types[type_dist(rng)];
        Decoded inst;
        inst.vld    = true;
        inst.opcode = t.opc;
        inst.rd     = reg_dist(rng);
        inst.rs1    = reg_dist(rng);
        inst.rs2    = reg_dist(rng);
        inst.funct3 = t.f3;
        inst.funct7 = t.f7;
        inst.imm    = val_dist(rng);

        uint32_t pc    = val_dist(rng) & ~3u;
        uint32_t rval1 = val_dist(rng);
        uint32_t rval2 = val_dist(rng);

        dut.eval(pc, inst, rval1, rval2);
        ExeResult ref = execute(pc, inst, rval1, rval2);
        ExeResult got = dut.result();

        if (got != ref) {
            std::cerr << "FAIL exe_random [" << i << "]"
                      << "  pc=0x" << std::hex << std::setfill('0')
                      << std::setw(8) << pc << std::dec
                      << "  opc=0x" << std::hex << std::setw(2) << (int)t.opc
                      << " f3=" << std::dec << (int)t.f3
                      << " f7=0x" << std::hex << std::setw(2) << (int)t.f7
                      << std::dec << "\n"
                      << "  expected: " << ref << "\n"
                      << "  got:      " << got << "\n";
            errors++;
        }
    }

    if (errors == 0)
        std::cout << "exe_random: PASS (" << n << " tests)" << std::endl;
    else
        std::cout << "exe_random: FAIL " << errors << " / " << n << std::endl;

    return errors;
}

static int test_dec_rf_exe_random(DecRfExeDut &dut, int n) {
    std::mt19937 rng(123);
    std::uniform_int_distribution<uint32_t> dist;

    RfRef rf_ref;
    int errors = 0;

    for (int i = 0; i < n; i++) {
        uint32_t pc   = dist(rng) & ~3u;
        uint32_t inst = dist(rng);

        dut.eval(pc, inst);
        ExeResult got = dut.result();

        Decoded d = decode(inst);
        uint32_t rval1 = rf_ref.read(d.rs1);
        uint32_t rval2 = rf_ref.read(d.rs2);
        ExeResult ref = execute(pc, d, rval1, rval2);

        if (got != ref) {
            std::cerr << "FAIL dec_rf_exe_random [" << i << "]"
                      << "  pc=0x" << std::hex << std::setfill('0')
                      << std::setw(8) << pc
                      << "  inst=0x" << std::setw(8) << inst
                      << std::dec << "\n"
                      << "  decoded:  " << d << "\n"
                      << "  rval1=0x" << std::hex << std::setfill('0')
                      << std::setw(8) << rval1
                      << "  rval2=0x" << std::setw(8) << rval2
                      << std::dec << "\n"
                      << "  expected: " << ref << "\n"
                      << "  got:      " << got << "\n";
            errors++;
        }
    }

    if (errors == 0)
        std::cout << "dec_rf_exe_random: PASS (" << n << " tests)" << std::endl;
    else
        std::cout << "dec_rf_exe_random: FAIL " << errors << " / " << n << std::endl;

    return errors;
}

static int test_fetch_random(FetchDut &dut, int n_rounds) {
    std::mt19937 rng(55);
    std::uniform_int_distribution<uint32_t> val_dist;
    std::uniform_int_distribution<int> len_dist(128, 256);

    FetchRef ref;
    int errors = 0;

    for (int r = 0; r < n_rounds; r++) {
        int n = len_dist(rng);

        dut.set_rst(true);
        dut.eval();

        for (int i = 0; i < n; i++) {
            uint32_t inst = val_dist(rng);
            ref.write(i * 4, inst);
            dut.write(i * 4, inst);
            dut.tick();
        }

        dut.clear_write();
        dut.set_rst(false);
        dut.eval();
        ref.reset();

        for (int i = 0; i < n; i++) {
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
            }

            dut.tick();
            ref.tick();
        }
    }

    if (errors == 0)
        std::cout << "fetch_random: PASS (" << n_rounds << " rounds)" << std::endl;
    else
        std::cout << "fetch_random: FAIL " << errors << std::endl;

    return errors;
}

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    int errors = 0;

    DecDut dec_dut;
    errors += test_dec_directed(dec_dut);
    errors += test_dec_random(dec_dut, 10000000);

    ExeDut exe_dut;
    errors += test_exe_directed(exe_dut);
    errors += test_exe_random(exe_dut, 1000000);

    RfDut rf_dut;
    errors += test_rf_directed(rf_dut);
    errors += test_rf_random(rf_dut, 1000000);

    DecRfExeDut dre_dut;
    errors += test_dec_rf_exe_random(dre_dut, 1000000);

    FetchDut fetch_dut;
    errors += test_fetch_random(fetch_dut, 10000);

    return errors ? EXIT_FAILURE : EXIT_SUCCESS;
}
