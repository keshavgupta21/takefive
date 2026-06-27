#pragma once
#include <cstdint>
#include "Vdec_wrap.h"
#include "Vrf_wrap.h"
#include "Vexe_wrap.h"
#include "Vbranch_wrap.h"
#include "Vfetch_wrap.h"
#include "Vcore_wrap.h"
#include "ref.h"

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
              uint32_t rval1, uint32_t rval2);
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
    uint32_t read_reg(uint8_t rs);
    uint32_t pc();

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
