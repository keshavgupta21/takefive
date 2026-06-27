#include "dut.h"

Dut::Dut() : model_(new Vdec_wrap) {
    model_->f2d_pc   = 0;
    model_->f2d_inst = 0;
    model_->eval();
}

Dut::~Dut() {
    model_->final();
    delete model_;
}

Decoded Dut::decode(uint32_t pc, uint32_t instr) {
    model_->f2d_pc   = pc;
    model_->f2d_inst = instr;
    model_->eval();

    Decoded d;
    d.opcode = model_->d2r_opc;
    d.rd     = model_->d2r_rd;
    d.rs1    = model_->d2r_rs1;
    d.rs2    = model_->d2r_rs2;
    d.funct3 = model_->d2r_funct3;
    d.funct7 = model_->d2r_funct7;
    d.imm    = model_->d2r_imm;
    return d;
}

uint32_t Dut::pc() const {
    return model_->d2r_pc;
}
