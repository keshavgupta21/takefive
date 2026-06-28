#pragma once
#include <cstdint>
#include "verilated.h"
#include "Vdec_wrap.h"
#include "Vrf_wrap.h"
#include "Vexe_wrap.h"
#include "Vbranch_wrap.h"
#include "Vmem_wrap.h"
#include "Vfetch_wrap.h"
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

class MemDut {
public:
    MemDut();
    ~MemDut();
    void eval(const Decoded& inst, uint32_t rval1, uint32_t rval2);
    MemReqResult result() const;

private:
    Vmem_wrap *model_;
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

class CoreDut {
public:
    CoreDut();
    ~CoreDut();
    void tick();
    void eval();
    void set_rst(bool r);
    void set_pause(bool p);
    void write(uint32_t addr, uint32_t data);
    void write_reg(uint8_t rd, uint32_t data);
    uint32_t read_reg(uint8_t rs);
    uint32_t pc();
    bool commit();

private:
    Vcore_wrap *model_;
};

class RfDut {
public:
    RfDut();
    ~RfDut();
    void tick();
    void set_read(uint8_t rs1, uint8_t rs2);
    void set_write(uint8_t rd, bool wen, uint32_t wdata);
    uint32_t rval1() const;
    uint32_t rval2() const;

private:
    Vrf_wrap *model_;
};
