#pragma once
#include <cstdint>
#include "Vdec_wrap.h"
#include "Vrf_wrap.h"
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
