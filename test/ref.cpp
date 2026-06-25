#include "ref.h"

void Ref::reset() {
    result_ = 0;
}

void Ref::step(uint8_t a, uint8_t b) {
    result_ = (a > b) ? a : b;
}

uint8_t Ref::result() const {
    return result_;
}
