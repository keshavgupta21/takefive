#include "ref.h"
#include <iomanip>

bool Decoded::operator==(const Decoded& o) const {
    return opcode == o.opcode && rd == o.rd && rs1 == o.rs1 &&
           rs2 == o.rs2 && funct3 == o.funct3 && funct7 == o.funct7 &&
           imm == o.imm;
}

bool Decoded::operator!=(const Decoded& o) const { return !(*this == o); }

std::ostream& operator<<(std::ostream& os, const Decoded& d) {
    os << "opcode=0x" << std::hex << std::setfill('0') << std::setw(2) << (int)d.opcode
       << " rd=" << std::dec << (int)d.rd
       << " rs1=" << (int)d.rs1
       << " rs2=" << (int)d.rs2
       << " f3=" << (int)d.funct3
       << " f7=0x" << std::hex << std::setw(2) << (int)d.funct7
       << " imm=0x" << std::setw(8) << d.imm << std::dec;
    return os;
}

static uint32_t sext(uint32_t val, int bits) {
    if ((val >> (bits - 1)) & 1)
        return val | (~0u << bits);
    return val;
}

Decoded decode(uint32_t instr) {
    Decoded d;
    d.opcode = instr & 0x7F;
    d.rd     = (instr >> 7) & 0x1F;
    d.rs1    = (instr >> 15) & 0x1F;
    d.rs2    = (instr >> 20) & 0x1F;
    d.funct3 = (instr >> 12) & 0x07;
    d.funct7 = (instr >> 25) & 0x7F;

    switch (d.opcode) {
        case 0x03: case 0x13: case 0x67:
            d.imm = sext((instr >> 20) & 0xFFF, 12);
            break;
        case 0x23:
            d.imm = sext((d.funct7 << 5) | d.rd, 12);
            break;
        case 0x63:
            d.imm = sext(
                (((instr >> 31) & 1) << 12) |
                (((instr >> 7)  & 1) << 11) |
                (((instr >> 25) & 0x3F) << 5) |
                (((instr >> 8)  & 0xF)  << 1),
                13);
            break;
        case 0x37: case 0x17:
            d.imm = instr & 0xFFFFF000;
            break;
        case 0x6F:
            d.imm = sext(
                (((instr >> 31) & 1)    << 20) |
                (((instr >> 12) & 0xFF) << 12) |
                (((instr >> 20) & 1)    << 11) |
                (((instr >> 21) & 0x3FF) << 1),
                21);
            break;
        default:
            d.imm = 0;
            break;
    }

    return d;
}
