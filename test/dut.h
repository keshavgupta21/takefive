#pragma once
#include <cstdint>
#include "Vdec_wrap.h"
#include "ref.h"

class Dut {
public:
    Dut();
    ~Dut();
    Decoded decode(uint32_t pc, uint32_t instr);
    uint32_t pc() const;

private:
    Vdec_wrap *model_;
};
