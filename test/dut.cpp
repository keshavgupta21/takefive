#include "dut.h"

Dut::Dut() : model_(new Vdec_wrap) {
    model_->f_pc   = 0;
    model_->f_inst = 0;
    model_->eval();
}

Dut::~Dut() {
    model_->final();
    delete model_;
}

Decoded Dut::decode(uint32_t pc, uint32_t instr) {
    model_->f_pc   = pc;
    model_->f_inst = instr;
    model_->eval();

    Decoded d;
    d.opcode = model_->d_inst_opc;
    d.rd     = model_->d_inst_rd;
    d.rs1    = model_->d_inst_rs1;
    d.rs2    = model_->d_inst_rs2;
    d.funct3 = model_->d_inst_funct3;
    d.funct7 = model_->d_inst_funct7;
    d.imm    = model_->d_inst_imm;
    return d;
}

uint32_t Dut::pc() const {
    return model_->d_pc;
}
