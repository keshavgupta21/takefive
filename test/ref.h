#pragma once
#include <cstdint>
#include <iostream>

struct Decoded {
    bool     valid;
    uint8_t  opcode;
    uint8_t  rd;
    uint8_t  rs1;
    uint8_t  rs2;
    uint8_t  funct3;
    uint8_t  funct7;
    uint32_t imm;

    bool operator==(const Decoded& o) const;
    bool operator!=(const Decoded& o) const;
};

std::ostream& operator<<(std::ostream& os, const Decoded& d);

Decoded decode(uint32_t instr);

inline uint32_t enc_r(uint8_t f7, uint8_t rs2, uint8_t rs1, uint8_t f3,
                      uint8_t rd, uint8_t op) {
    return (f7 << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | op;
}

inline uint32_t enc_i(int32_t imm, uint8_t rs1, uint8_t f3,
                      uint8_t rd, uint8_t op) {
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | op;
}

inline uint32_t enc_s(int32_t imm, uint8_t rs2, uint8_t rs1, uint8_t f3,
                      uint8_t op) {
    uint32_t i = imm & 0xFFF;
    return ((i >> 5) << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12)
         | ((i & 0x1F) << 7) | op;
}

inline uint32_t enc_b(int32_t imm, uint8_t rs2, uint8_t rs1, uint8_t f3,
                      uint8_t op) {
    uint32_t i = imm & 0x1FFF;
    return (((i >> 12) & 1) << 31) | (((i >> 5) & 0x3F) << 25)
         | (rs2 << 20) | (rs1 << 15) | (f3 << 12)
         | (((i >> 1) & 0xF) << 8) | (((i >> 11) & 1) << 7) | op;
}

inline uint32_t enc_u(uint32_t imm, uint8_t rd, uint8_t op) {
    return (imm & 0xFFFFF000) | (rd << 7) | op;
}

inline uint32_t enc_j(int32_t imm, uint8_t rd, uint8_t op) {
    uint32_t i = imm & 0x1FFFFF;
    return (((i >> 20) & 1) << 31) | (((i >> 1) & 0x3FF) << 21)
         | (((i >> 11) & 1) << 20) | (((i >> 12) & 0xFF) << 12)
         | (rd << 7) | op;
}
