#include "dut.h"
#include <cstring>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <vector>
#include <functional>

#ifdef WAVES
static VerilatedVcdC* g_trace = nullptr;
static uint64_t g_time = 0;
static const char* g_trace_filename = nullptr;
static std::vector<std::function<void()>> g_trace_cbs;

void waves_init() {
    Verilated::traceEverOn(true);
    g_trace = new VerilatedVcdC;
}

void waves_open(const char* filename) {
    g_trace_filename = filename;
    if (g_trace) g_trace->open(filename);
}

void waves_reset() {
    if (!g_trace) return;
    g_trace->close();
    delete g_trace;
    g_trace = new VerilatedVcdC;
    g_time = 0;
    for (auto& cb : g_trace_cbs) cb();
    g_trace->open(g_trace_filename);
}

void waves_close() {
    if (g_trace) {
        g_trace->close();
        delete g_trace;
        g_trace = nullptr;
    }
}
#endif

// ---- DecDut ----

DecDut::DecDut() : model_(new Vdec_wrap) {
    model_->f_vld  = 1;
    model_->f_pc   = 0;
    model_->f_inst = 0;
    model_->eval();
}

DecDut::~DecDut() {
    model_->final();
    delete model_;
}

Decoded DecDut::decode(uint32_t pc, uint32_t instr) {
    model_->f_vld  = 1;
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
    model_->pc            = 0;
    model_->inst_vld      = 0;
    model_->inst_opc      = 0;
    model_->inst_rd       = 0;
    model_->inst_rs1      = 0;
    model_->inst_rs2      = 0;
    model_->inst_funct3   = 0;
    model_->inst_funct7   = 0;
    model_->inst_imm      = 0;
    model_->rval1    = 0;
    model_->rval2    = 0;
    model_->mem_data = 0;
    model_->eval();
}

ExeDut::~ExeDut() {
    model_->final();
    delete model_;
}

void ExeDut::eval(uint32_t pc, const Decoded& inst,
                  uint32_t rval1, uint32_t rval2, uint32_t dmem_data) {
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
    model_->mem_data    = dmem_data;
    model_->eval();
}

ExeResult ExeDut::result() const {
    ExeResult r;
    r.rfwb_rd    = model_->rf_wr_req_rd;
    r.rfwb_wen   = model_->rf_wr_req_wen;
    r.rfwb_wdata = model_->rf_wr_req_wdata;
    return r;
}

// ---- BranchDut ----

BranchDut::BranchDut() : model_(new Vbranch_wrap) {
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

BranchDut::~BranchDut() {
    model_->final();
    delete model_;
}

void BranchDut::eval(uint32_t pc, const Decoded& inst,
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

NxtPcResult BranchDut::result() const {
    NxtPcResult r;
    r.vld    = model_->annul_annul;
    r.pc     = model_->annul_pc;
    r.nxt_pc = model_->annul_nxt_pc;
    return r;
}

// ---- FetchDut ----

FetchDut::FetchDut() : model_(new Vfetch_wrap) {
    model_->clk           = 0;
    model_->rst           = 1;
    model_->wr_addr       = 0;
    model_->wr_data       = 0;
    model_->wr_en         = 0;
    model_->annul_annul  = 0;
    model_->annul_pc     = 0;
    model_->annul_nxt_pc = 0;
    model_->dbg_pause     = 0;
    model_->eval();
#ifdef WAVES
    if (g_trace) {
        model_->trace(g_trace, 99);
        g_trace_cbs.push_back([this]() { model_->trace(g_trace, 99); });
    }
#endif
}

FetchDut::~FetchDut() {
    model_->final();
    delete model_;
}

void FetchDut::tick() {
    model_->clk = 0;
    model_->eval();
#ifdef WAVES
    if (g_trace) g_trace->dump(g_time++);
#endif
    model_->clk = 1;
    model_->eval();
#ifdef WAVES
    if (g_trace) g_trace->dump(g_time++);
#endif
}

void FetchDut::eval() {
    model_->eval();
}

void FetchDut::set_rst(bool r) {
    model_->rst = r;
}

void FetchDut::set_nxt_pc(bool vld, uint32_t pc, uint32_t nxt_pc) {
    model_->annul_annul  = vld;
    model_->annul_pc     = pc;
    model_->annul_nxt_pc = nxt_pc;
}

void FetchDut::write(uint32_t addr, uint32_t data) {
    model_->dbg_pause = 1;
    model_->wr_en     = 1;
    model_->wr_addr   = addr;
    model_->wr_data   = data;
    model_->eval();
}

void FetchDut::clear_write() {
    model_->dbg_pause = 0;
    model_->wr_en     = 0;
    model_->eval();
}

bool FetchDut::f_vld() const { return model_->f_vld; }
uint32_t FetchDut::f_pc() const { return model_->f_pc; }
uint32_t FetchDut::f_inst() const { return model_->f_inst; }

// ---- ICacheDut ----

ICacheDut::ICacheDut() : model_(new Vicache_wrap) {
    model_->clk          = 0;
    model_->rst          = 1;
    model_->dbg_pause    = 0;
    model_->wr_addr      = 0;
    model_->wr_data      = 0;
    model_->wr_en        = 0;
    model_->mem_req_vld  = 0;
    model_->mem_req_addr = 0;
    model_->eval();
#ifdef WAVES
    if (g_trace) {
        model_->trace(g_trace, 99);
        g_trace_cbs.push_back([this]() { model_->trace(g_trace, 99); });
    }
#endif
}

ICacheDut::~ICacheDut() {
    model_->final();
    delete model_;
}

void ICacheDut::tick() {
    model_->clk = 0;
    model_->eval();
#ifdef WAVES
    if (g_trace) g_trace->dump(g_time++);
#endif
    model_->clk = 1;
    model_->eval();
#ifdef WAVES
    if (g_trace) g_trace->dump(g_time++);
#endif
}

void ICacheDut::eval() {
    model_->eval();
}

void ICacheDut::set_rst(bool r) {
    model_->rst = r;
}

void ICacheDut::write(uint32_t addr, uint32_t data) {
    model_->dbg_pause = 1;
    model_->wr_en     = 1;
    model_->wr_addr   = addr;
    model_->wr_data   = data;
    model_->eval();
}

void ICacheDut::clear_write() {
    model_->dbg_pause = 0;
    model_->wr_en     = 0;
    model_->eval();
}

void ICacheDut::set_req(uint32_t addr) {
    model_->mem_req_vld  = 1;
    model_->mem_req_addr = addr;
    model_->eval();
}

bool     ICacheDut::rsp_vld()  const { return model_->mem_rsp_vld;  }
uint32_t ICacheDut::rsp_data() const { return model_->mem_rsp_data; }
uint32_t ICacheDut::rsp_uid()  const { return model_->mem_rsp_uid;  }
bool     ICacheDut::rdy()      const { return model_->mem_rdy;      }

// ---- DCacheDut ----

DCacheDut::DCacheDut() : model_(new Vdcache_wrap) {
    model_->clk          = 0;
    model_->rst          = 1;
    model_->dbg_pause    = 0;
    model_->wr_addr      = 0;
    model_->wr_data      = 0;
    model_->wr_en        = 0;
    model_->mem_req_vld  = 0;
    model_->mem_req_addr = 0;
    model_->mem_req_wen  = 0;
    model_->mem_req_data = 0;
    model_->eval();
#ifdef WAVES
    if (g_trace) {
        model_->trace(g_trace, 99);
        g_trace_cbs.push_back([this]() { model_->trace(g_trace, 99); });
    }
#endif
}

DCacheDut::~DCacheDut() {
    model_->final();
    delete model_;
}

void DCacheDut::tick() {
    model_->clk = 0;
    model_->eval();
#ifdef WAVES
    if (g_trace) g_trace->dump(g_time++);
#endif
    model_->clk = 1;
    model_->eval();
#ifdef WAVES
    if (g_trace) g_trace->dump(g_time++);
#endif
}

void DCacheDut::eval() {
    model_->eval();
}

void DCacheDut::set_rst(bool r) {
    model_->rst = r;
}

void DCacheDut::write(uint32_t addr, uint32_t data) {
    model_->dbg_pause = 1;
    model_->wr_en     = 1;
    model_->wr_addr   = addr;
    model_->wr_data   = data;
    model_->eval();
}

void DCacheDut::clear_write() {
    model_->dbg_pause = 0;
    model_->wr_en     = 0;
    model_->eval();
}

void DCacheDut::set_req(uint32_t addr, bool wen, uint32_t data) {
    model_->mem_req_vld  = 1;
    model_->mem_req_addr = addr;
    model_->mem_req_wen  = wen;
    model_->mem_req_data = data;
    model_->eval();
}

bool     DCacheDut::rsp_vld()  const { return model_->mem_rsp_vld;  }
uint32_t DCacheDut::rsp_data() const { return model_->mem_rsp_data; }
uint32_t DCacheDut::rsp_uid()  const { return model_->mem_rsp_uid;  }
bool     DCacheDut::rdy()      const { return model_->mem_rdy;      }

// ---- CoreDut ----

CoreDut::CoreDut() : model_(new Vcore_wrap) {
    std::memset(imem_, 0, sizeof(imem_));
    std::memset(dmem_, 0, sizeof(dmem_));
    std::memset(mmio_, 0, sizeof(mmio_));
#ifdef WAVES
    if (g_trace) {
        model_->trace(g_trace, 99);
        g_trace_cbs.push_back([this]() { model_->trace(g_trace, 99); });
    }
#endif

    model_->clk          = 0;
    model_->rst          = 1;
    model_->dbg_pause    = 1;
    model_->imem_wr_addr = 0;
    model_->imem_wr_data = 0;
    model_->imem_wr_en   = 0;
    model_->dmem_wr_addr = 0;
    model_->dmem_wr_data = 0;
    model_->dmem_wr_en   = 0;
    model_->mmio_rsp_vld  = 0;
    model_->mmio_rsp_data = 0;
    model_->mmio_rsp_uid  = 0;
    model_->mmio_rdy      = 0;
    model_->eval();
}

CoreDut::~CoreDut() {
    model_->final();
    delete model_;
}

bool CoreDut::load_imem(const std::string& path) {
    std::ifstream f(path);
    if (!f) return false;
    for (int i = 0; i < DRAM_WORDS; i++)
        if (!(f >> std::hex >> imem_[i])) break;
    return true;
}

bool CoreDut::load_dmem(const std::string& path) {
    std::ifstream f(path);
    if (!f) return false;
    for (int i = 0; i < DRAM_WORDS; i++)
        if (!(f >> std::hex >> dmem_[i])) break;
    return true;
}

void CoreDut::tick() {
    model_->clk = 0;
    model_->eval();
#ifdef WAVES
    if (g_trace) g_trace->dump(g_time++);
#endif
    model_->clk = 1;
    model_->eval();
#ifdef WAVES
    if (g_trace) g_trace->dump(g_time++);
#endif
}

void CoreDut::program() {
    for (int i = 0; i < DRAM_WORDS; i++) {
        model_->imem_wr_en   = 1;
        model_->imem_wr_addr = i * 4;
        model_->imem_wr_data = imem_[i];
        tick();
    }
    model_->imem_wr_en = 0;

    for (int i = 0; i < DRAM_WORDS; i++) {
        model_->dmem_wr_en   = 1;
        model_->dmem_wr_addr = i * 4;
        model_->dmem_wr_data = dmem_[i];
        tick();
    }
    model_->dmem_wr_en = 0;
}

uint32_t CoreDut::mmio(int i) const { return mmio_[i]; }

bool CoreDut::run(int max_steps) {
    program();

    model_->rst       = 0;
    model_->dbg_pause = 0;
    model_->mmio_rdy  = 1;

    bool     pending_rsp  = false;
    uint32_t pending_data = 0;
    uint32_t pending_uid  = 0;

    for (int step = 0; step < max_steps; step++) {
        model_->mmio_rsp_vld  = pending_rsp ? 1 : 0;
        model_->mmio_rsp_data = pending_data;
        model_->mmio_rsp_uid  = pending_uid;
        pending_rsp = false;

        tick();

        if (model_->mmio_req_vld) {
            uint32_t addr = model_->mmio_req_addr;
            if (model_->mmio_req_wen) {
                if (addr == 0xFFFFFFFC) {
                    model_->rst       = 1;
                    model_->dbg_pause = 1;
                    model_->eval();
                    return true;
                }
                if (addr == 0xFFFFFFF8) {
                    std::cout << (char)(model_->mmio_req_data & 0xFF);
                }
                mmio_[(addr & 0xFFu) >> 2] = model_->mmio_req_data;
            } else {
                pending_rsp  = true;
                pending_data = mmio_[(addr & 0xFFu) >> 2];
                pending_uid  = model_->mmio_req_uid;
            }
        }
    }
    return false;
}
