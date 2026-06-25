#include "dut.h"

Dut::Dut() : model_(new Vcore) {
    model_->clk = 0;
    model_->rst = 1;
    model_->a = 0;
    model_->b = 0;
    model_->eval();
}

Dut::~Dut() {
    model_->final();
    delete model_;
}

void Dut::reset() {
    model_->rst = 1;
    tick();
    model_->rst = 0;
}

void Dut::step(uint8_t a, uint8_t b) {
    model_->a = a;
    model_->b = b;
    tick();
}

uint8_t Dut::result() const {
    return model_->result;
}

void Dut::tick() {
    model_->clk = 1;
    model_->eval();
    model_->clk = 0;
    model_->eval();
}
