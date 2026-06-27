#pragma once
#include <cstdint>
#include <iostream>

struct Decoded {
    bool     vld;
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
uint32_t pack(const Decoded& d);

class RfRef {
public:
    RfRef();
    void write(uint8_t rd, bool wen, uint32_t wdata);
    uint32_t read(uint8_t rs) const;

private:
    uint32_t regs_[32];
};

struct ExeResult {
    uint8_t  rfwb_rd;
    bool     rfwb_wen;
    uint32_t rfwb_wdata;

    bool operator==(const ExeResult& o) const;
    bool operator!=(const ExeResult& o) const;
};

std::ostream& operator<<(std::ostream& os, const ExeResult& r);

uint32_t alu(uint32_t op_a, uint32_t op_b, uint8_t funct3, bool sub);
ExeResult execute(uint32_t pc, const Decoded& inst,
                  uint32_t rval1, uint32_t rval2);

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
