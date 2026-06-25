#pragma once
#include <cstdint>

class Ref {
public:
    void reset();
    void step(uint8_t a, uint8_t b);
    uint8_t result() const;

private:
    uint8_t result_ = 0;
};
