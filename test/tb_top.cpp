#include <cstdlib>
#include <iostream>
#include "verilated.h"
#include "ref.h"
#include "dut.h"

struct Stimulus {
    uint8_t a;
    uint8_t b;
};

static const Stimulus tests[] = {
    {  0,   0},
    {  1,   0},
    {  0,   1},
    { 42,  17},
    { 17,  42},
    {100, 100},
    {255,   0},
    {  0, 255},
    {255, 255},
    {128, 127},
    {127, 128},
};

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    Ref ref;
    Dut dut;

    ref.reset();
    dut.reset();

    int num_errors = 0;
    int num_tests = sizeof(tests) / sizeof(tests[0]);

    for (int i = 0; i < num_tests; i++) {
        uint8_t a = tests[i].a;
        uint8_t b = tests[i].b;

        ref.step(a, b);
        dut.step(a, b);

        if (dut.result() != ref.result()) {
            std::cerr << "FAIL: test " << i
                      << " a=" << (int)a << " b=" << (int)b
                      << " expected=" << (int)ref.result()
                      << " got=" << (int)dut.result() << std::endl;
            num_errors++;
        }
    }

    if (num_errors == 0)
        std::cout << "PASS: all " << num_tests << " tests matched" << std::endl;
    else
        std::cout << "FAIL: " << num_errors << " errors" << std::endl;

    return num_errors ? EXIT_FAILURE : EXIT_SUCCESS;
}
