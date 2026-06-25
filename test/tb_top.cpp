#include <cstdlib>
#include <iostream>
#include "Vtop.h"
#include "verilated.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    Vtop *dut = new Vtop;

    // Reset
    dut->clk = 0;
    dut->rst_n = 0;
    dut->in_data = 0;
    dut->eval();

    dut->clk = 1;
    dut->eval();
    dut->clk = 0;
    dut->eval();

    dut->rst_n = 1;

    int num_errors = 0;

    for (int i = 0; i < 256; i++) {
        dut->in_data = i;

        // Rising edge
        dut->clk = 1;
        dut->eval();
        // Falling edge
        dut->clk = 0;
        dut->eval();

        if (dut->out_data != i) {
            std::cerr << "FAIL: cycle " << i
                      << " expected " << i
                      << " got " << (int)dut->out_data << std::endl;
            num_errors++;
        }
    }

    if (num_errors == 0)
        std::cout << "PASS: all 256 values matched" << std::endl;
    else
        std::cout << "FAIL: " << num_errors << " errors" << std::endl;

    dut->final();
    delete dut;

    return num_errors ? EXIT_FAILURE : EXIT_SUCCESS;
}
