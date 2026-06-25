#pragma once
#include <cstdint>
#include "Vcore.h"

class Dut {
public:
    Dut();
    ~Dut();
    void reset();
    void step(uint8_t a, uint8_t b);
    uint8_t result() const;

private:
    Vcore *model_;
    void tick();
};
