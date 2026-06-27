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
    d.vld  = model_->d_inst_vld;
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

// ---- ExeDut ----

ExeDut::ExeDut() : model_(new Vexe_wrap) {
    model_->pc          = 0;
    model_->inst_vld    = 0;
    model_->inst_opc    = 0;
    model_->inst_rd     = 0;
    model_->inst_rs1    = 0;
    model_->inst_rs2    = 0;
    model_->inst_funct3 = 0;
    model_->inst_funct7 = 0;
    model_->inst_imm    = 0;
    model_->rval1       = 0;
    model_->rval2       = 0;
    model_->eval();
}

ExeDut::~ExeDut() {
    model_->final();
    delete model_;
}

void ExeDut::eval(uint32_t pc, const Decoded& inst,
                  uint32_t rval1, uint32_t rval2) {
    model_->pc          = pc;
    model_->inst_vld    = inst.vld;
    model_->inst_opc    = inst.opcode;
    model_->inst_rd     = inst.rd;
    model_->inst_rs1    = inst.rs1;
    model_->inst_rs2    = inst.rs2;
    model_->inst_funct3 = inst.funct3;
    model_->inst_funct7 = inst.funct7;
    model_->inst_imm    = inst.imm;
    model_->rval1       = rval1;
    model_->rval2       = rval2;
    model_->eval();
}

ExeResult ExeDut::result() const {
    ExeResult r;
    r.rfwb_rd    = model_->rfwb_rd;
    r.rfwb_wen   = model_->rfwb_wen;
    r.rfwb_wdata = model_->rfwb_wdata;
    return r;
}

// ---- DecRfExeDut ----

DecRfExeDut::DecRfExeDut() : model_(new Vdec_rf_exe_wrap) {
    model_->clk    = 0;
    model_->f_pc   = 0;
    model_->f_inst = 0;
    model_->eval();
}

DecRfExeDut::~DecRfExeDut() {
    model_->final();
    delete model_;
}

void DecRfExeDut::eval(uint32_t pc, uint32_t inst) {
    model_->f_pc   = pc;
    model_->f_inst = inst;
    model_->eval();
}

ExeResult DecRfExeDut::result() const {
    ExeResult r;
    r.rfwb_rd    = model_->rfwb_rd;
    r.rfwb_wen   = model_->rfwb_wen;
    r.rfwb_wdata = model_->rfwb_wdata;
    return r;
}

// ---- FetchDut ----

FetchDut::FetchDut() : model_(new Vfetch_wrap) {
    model_->clk     = 0;
    model_->rst     = 1;
    model_->wr_addr = 0;
    model_->wr_data = 0;
    model_->wr_en   = 0;
    model_->eval();
}

FetchDut::~FetchDut() {
    model_->final();
    delete model_;
}

void FetchDut::tick() {
    model_->clk = 0;
    model_->eval();
    model_->clk = 1;
    model_->eval();
}

void FetchDut::eval() {
    model_->eval();
}

void FetchDut::set_rst(bool r) {
    model_->rst = r;
}

void FetchDut::write(uint32_t addr, uint32_t data) {
    model_->wr_en   = 1;
    model_->wr_addr = addr;
    model_->wr_data = data;
    model_->eval();
}

void FetchDut::clear_write() {
    model_->wr_en = 0;
    model_->eval();
}

uint32_t FetchDut::f_pc() const { return model_->f_pc; }
uint32_t FetchDut::f_inst() const { return model_->f_inst; }

// ---- RfDut ----

RfDut::RfDut() : model_(new Vrf_wrap) {
    model_->clk        = 0;
    model_->rs1        = 0;
    model_->rs2        = 0;
    model_->rfwb_rd    = 0;
    model_->rfwb_wen   = 0;
    model_->rfwb_wdata = 0;
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
    model_->rfwb_rd    = rd;
    model_->rfwb_wen   = wen;
    model_->rfwb_wdata = wdata;
}

uint32_t RfDut::rval1() const { return model_->rval1; }
uint32_t RfDut::rval2() const { return model_->rval2; }
