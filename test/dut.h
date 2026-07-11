#pragma once
#include <cstdint>
#include <string>
#include "verilated.h"
#include "Vdec_wrap.h"
#include "Vexe_wrap.h"
#include "Vbranch_wrap.h"
#include "Vfetch_wrap.h"
#include "Vicache_wrap.h"
#include "Vdcache_wrap.h"
#include "Vcore_wrap.h"
#include "ref.h"

#ifdef WAVES
#include "verilated_vcd_c.h"
void waves_init();
void waves_open(const char* filename);
void waves_reset();
void waves_close();
#else
inline void waves_reset() {}
#endif

class DecDut {
public:
    DecDut();
    ~DecDut();
    Decoded decode(uint32_t pc, uint32_t instr);
    uint32_t pc() const;

private:
    Vdec_wrap *model_;
};

class ExeDut {
public:
    ExeDut();
    ~ExeDut();
    void eval(uint32_t pc, const Decoded& inst,
              uint32_t rval1, uint32_t rval2, uint32_t dmem_data = 0);
    ExeResult result() const;

private:
    Vexe_wrap *model_;
};

class BranchDut {
public:
    BranchDut();
    ~BranchDut();
    void eval(uint32_t pc, const Decoded& inst,
              uint32_t rval1, uint32_t rval2);
    NxtPcResult result() const;

private:
    Vbranch_wrap *model_;
};

class FetchDut {
public:
    FetchDut();
    ~FetchDut();
    void tick();
    void eval();
    void set_rst(bool r);
    void set_nxt_pc(bool vld, uint32_t pc, uint32_t nxt_pc);
    void write(uint32_t addr, uint32_t data);
    void clear_write();
    bool f_vld() const;
    uint32_t f_pc() const;
    uint32_t f_inst() const;

private:
    Vfetch_wrap *model_;
};

class ICacheDut {
public:
    ICacheDut();
    ~ICacheDut();
    void tick();
    void eval();
    void set_rst(bool r);
    void write(uint32_t addr, uint32_t data);
    void clear_write();
    void set_req(uint32_t addr);
    bool rsp_vld() const;
    uint32_t rsp_data() const;
    uint32_t rsp_uid() const;
    bool rdy() const;

private:
    Vicache_wrap *model_;
};

class DCacheDut {
public:
    DCacheDut();
    ~DCacheDut();
    void tick();
    void eval();
    void set_rst(bool r);
    void write(uint32_t addr, uint32_t data);
    void clear_write();
    void set_req(uint32_t addr, bool wen, uint32_t data);
    bool rsp_vld() const;
    uint32_t rsp_data() const;
    uint32_t rsp_uid() const;
    bool rdy() const;

private:
    Vdcache_wrap *model_;
};

class CoreDut {
public:
    CoreDut();
    ~CoreDut();
    bool     load_imem(const std::string& path);
    bool     load_dmem(const std::string& path);
    bool     run(int max_steps = 1000000);
    uint32_t mmio(int i)      const;
    uint64_t committed()      const;
    uint64_t cycles()         const;

private:
    Vcore_wrap *model_;
    uint32_t    imem_[DRAM_WORDS];
    uint32_t    dmem_[DRAM_WORDS];
    uint32_t    mmio_[MMIO_WORDS];
    uint32_t    imem_base_;
    uint32_t    dmem_base_;
    uint64_t    committed_;
    uint64_t    cycles_;
    bool        dmem_pending_b_;
    uint32_t    dmem_aw_addr_;

    void     tick();
    void     configure();
    void     service_axi();
    uint32_t axi_read(uint8_t byte_off);
    void     axi_write(uint8_t byte_off, uint32_t data);
};
