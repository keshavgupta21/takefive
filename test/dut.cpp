#include "dut.h"

// ---- DecDut ----

DecDut::DecDut() : model_(new Vdec_wrap) {
    model_->f_pc   = 0;
    model_->f_inst = 0;
    model_->eval();
}

DecDut::~DecDut() {
    model_->final();
    delete model_;
}

Decoded DecDut::decode(uint32_t pc, uint32_t instr) {
    model_->f_pc   = pc;
    model_->f_inst = instr;
    model_->eval();

    Decoded d;
    d.valid  = model_->d_inst_valid;
    d.opcode = model_->d_inst_opc;
    d.rd     = model_->d_inst_rd;
    d.rs1    = model_->d_inst_rs1;
    d.rs2    = model_->d_inst_rs2;
    d.funct3 = model_->d_inst_funct3;
    d.funct7 = model_->d_inst_funct7;
    d.imm    = model_->d_inst_imm;
    return d;
}

uint32_t DecDut::pc() const {
    return model_->d_pc;
}

// ---- RfDut ----

RfDut::RfDut() : model_(new Vrf_wrap) {
    model_->clk   = 0;
    model_->rs1   = 0;
    model_->rs2   = 0;
    model_->rd    = 0;
    model_->wen   = 0;
    model_->wdata = 0;
    model_->eval();
}

RfDut::~RfDut() {
    model_->final();
    delete model_;
}

void RfDut::tick() {
    model_->clk = 0;
    model_->eval();
    model_->clk = 1;
    model_->eval();
}

void RfDut::set_read(uint8_t rs1, uint8_t rs2) {
    model_->rs1 = rs1;
    model_->rs2 = rs2;
    model_->eval();
}

void RfDut::set_write(uint8_t rd, bool wen, uint32_t wdata) {
    model_->rd    = rd;
    model_->wen   = wen;
    model_->wdata = wdata;
}

uint32_t RfDut::rval1() const { return model_->rval1; }
uint32_t RfDut::rval2() const { return model_->rval2; }
