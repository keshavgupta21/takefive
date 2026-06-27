#include "ref.h"
#include <iomanip>

bool Decoded::operator==(const Decoded& o) const {
    return vld == o.vld && opcode == o.opcode && rd == o.rd &&
           rs1 == o.rs1 && rs2 == o.rs2 && funct3 == o.funct3 &&
           funct7 == o.funct7 && imm == o.imm;
}

bool Decoded::operator!=(const Decoded& o) const { return !(*this == o); }

std::ostream& operator<<(std::ostream& os, const Decoded& d) {
    os << (d.vld ? "V" : "-")
       << " opc=0x" << std::hex << std::setfill('0') << std::setw(2) << (int)d.opcode
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

static bool is_valid_rv32i(uint8_t opcode, uint8_t funct3, uint8_t funct7) {
    switch (opcode) {
        case 0x33: // R-type
            switch (funct3) {
                case 0: case 5: return funct7 == 0x00 || funct7 == 0x20;
                default:        return funct7 == 0x00;
            }
        case 0x13: // I-type arithmetic
            switch (funct3) {
                case 1:  return funct7 == 0x00;
                case 5:  return funct7 == 0x00 || funct7 == 0x20;
                default: return true;
            }
        case 0x03: // Loads
            return funct3 != 3 && funct3 != 6 && funct3 != 7;
        case 0x23: // Stores
            return funct3 == 0 || funct3 == 1 || funct3 == 2;
        case 0x63: // Branches
            return funct3 != 2 && funct3 != 3;
        case 0x67: // JALR
            return funct3 == 0;
        case 0x37: case 0x17: // LUI, AUIPC
            return true;
        case 0x6F: // JAL
            return true;
        case 0x0F: // FENCE
            return funct3 == 0;
        case 0x73: // ECALL, EBREAK
            return funct3 == 0;
        default:
            return false;
    }
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

    d.vld = is_valid_rv32i(d.opcode, d.funct3, d.funct7);

    return d;
}

Decoded make_inst(bool vld, uint8_t opc, uint8_t rd, uint8_t rs1,
                  uint8_t rs2, uint8_t f3, uint8_t f7, uint32_t imm) {
    Decoded d;
    d.vld    = vld;
    d.opcode = opc;
    d.rd     = rd;
    d.rs1    = rs1;
    d.rs2    = rs2;
    d.funct3 = f3;
    d.funct7 = f7;
    d.imm    = imm;
    return d;
}

const InstType INST_TYPES[] = {
    {0x33, 0, 0x00}, {0x33, 0, 0x20}, {0x33, 1, 0x00}, {0x33, 2, 0x00},
    {0x33, 3, 0x00}, {0x33, 4, 0x00}, {0x33, 5, 0x00}, {0x33, 5, 0x20},
    {0x33, 6, 0x00}, {0x33, 7, 0x00},
    {0x13, 0, 0x00}, {0x13, 2, 0x00}, {0x13, 3, 0x00}, {0x13, 4, 0x00},
    {0x13, 6, 0x00}, {0x13, 7, 0x00}, {0x13, 1, 0x00}, {0x13, 5, 0x00},
    {0x13, 5, 0x20},
    {0x37, 0, 0x00}, {0x17, 0, 0x00},
    {0x6F, 0, 0x00}, {0x67, 0, 0x00},
};
const int N_INST_TYPES = sizeof(INST_TYPES) / sizeof(INST_TYPES[0]);

Decoded gen_random_inst(std::mt19937 &rng) {
    std::uniform_int_distribution<uint32_t> val_dist;
    std::uniform_int_distribution<int>      type_dist(0, N_INST_TYPES - 1);
    std::uniform_int_distribution<uint8_t>  reg_dist(0, 31);

    const InstType &t = INST_TYPES[type_dist(rng)];
    return make_inst(true, t.opc, reg_dist(rng), reg_dist(rng), reg_dist(rng),
                     t.f3, t.f7, val_dist(rng));
}

uint32_t pack(const Decoded& d) {
    switch (d.opcode) {
        case 0x33: // R-type
            return enc_r(d.funct7, d.rs2, d.rs1, d.funct3, d.rd, d.opcode);
        case 0x13: // I-type arithmetic
            if (d.funct3 == 1 || d.funct3 == 5)
                return enc_r(d.funct7, d.imm & 0x1F, d.rs1, d.funct3, d.rd, d.opcode);
            return enc_i(d.imm, d.rs1, d.funct3, d.rd, d.opcode);
        case 0x03: case 0x67: case 0x0F: case 0x73: // LOAD, JALR, FENCE, SYSTEM
            return enc_i(d.imm, d.rs1, d.funct3, d.rd, d.opcode);
        case 0x23: // S-type
            return enc_s(d.imm, d.rs2, d.rs1, d.funct3, d.opcode);
        case 0x63: // B-type
            return enc_b(d.imm, d.rs2, d.rs1, d.funct3, d.opcode);
        case 0x37: case 0x17: // U-type
            return enc_u(d.imm, d.rd, d.opcode);
        case 0x6F: // J-type
            return enc_j(d.imm, d.rd, d.opcode);
        default:
            return enc_r(d.funct7, d.rs2, d.rs1, d.funct3, d.rd, d.opcode);
    }
}

// ---- ExeResult ----

bool ExeResult::operator==(const ExeResult& o) const {
    return rfwb_rd == o.rfwb_rd && rfwb_wen == o.rfwb_wen &&
           rfwb_wdata == o.rfwb_wdata;
}

bool ExeResult::operator!=(const ExeResult& o) const { return !(*this == o); }

std::ostream& operator<<(std::ostream& os, const ExeResult& r) {
    os << "rd=" << (int)r.rfwb_rd
       << " wen=" << r.rfwb_wen
       << " wdata=0x" << std::hex << std::setfill('0')
       << std::setw(8) << r.rfwb_wdata << std::dec;
    return os;
}

uint32_t alu(uint32_t op_a, uint32_t op_b, uint8_t funct3, bool sub, bool ari) {
    switch (funct3) {
        case 0: return sub ? op_a - op_b : op_a + op_b;
        case 1: return op_a << (op_b & 0x1F);
        case 2: return (int32_t)op_a < (int32_t)op_b ? 1 : 0;
        case 3: return op_a < op_b ? 1 : 0;
        case 4: return op_a ^ op_b;
        case 5: return ari ? (uint32_t)((int32_t)op_a >> (op_b & 0x1F))
                           : op_a >> (op_b & 0x1F);
        case 6: return op_a | op_b;
        case 7: return op_a & op_b;
        default: return 0;
    }
}

ExeResult execute(uint32_t pc, const Decoded& inst,
                  uint32_t rval1, uint32_t rval2) {
    ExeResult r;
    r.rfwb_rd    = inst.rd;
    r.rfwb_wen   = false;
    r.rfwb_wdata = 0;

    if (!inst.vld) return r;

    bool sub = (inst.funct7 >> 5) & 1;
    bool ari = (inst.funct7 >> 5) & 1;

    switch (inst.opcode) {
        case 0x33: // REG
            r.rfwb_wen   = true;
            r.rfwb_wdata = alu(rval1, rval2, inst.funct3, sub, ari);
            break;
        case 0x13: // IMM
            r.rfwb_wen   = true;
            r.rfwb_wdata = alu(rval1, inst.imm, inst.funct3, false, ari);
            break;
        case 0x37: // LUI
            r.rfwb_wen   = true;
            r.rfwb_wdata = inst.imm;
            break;
        case 0x17: // AUIPC
            r.rfwb_wen   = true;
            r.rfwb_wdata = pc + inst.imm;
            break;
        case 0x6F: // JAL
            r.rfwb_wen   = true;
            r.rfwb_wdata = pc + 4;
            break;
        case 0x67: // JALR
            r.rfwb_wen   = true;
            r.rfwb_wdata = pc + 4;
            break;
        default:
            break;
    }

    return r;
}

// ---- RfRef ----

RfRef::RfRef() {
    regs_[0] = 0;
    for (int i = 1; i < 32; i++)
        regs_[i] = 0x01010101u * i;
}

void RfRef::write(uint8_t rd, bool wen, uint32_t wdata) {
    if (wen) regs_[rd] = wdata;
}

uint32_t RfRef::read(uint8_t rs) const {
    if (rs == 0) return 0;
    return regs_[rs];
}

// ---- FetchRef ----

FetchRef::FetchRef(size_t depth) : pc_(0), mem_(depth, 0) {}

void FetchRef::reset() { pc_ = 0; }

void FetchRef::write(uint32_t addr, uint32_t data) {
    mem_[addr >> 2] = data;
}

void FetchRef::tick() { pc_ += 4; }

uint32_t FetchRef::pc() const { return pc_; }

uint32_t FetchRef::inst() const { return mem_[pc_ >> 2]; }

// ---- CoreRef ----

CoreRef::CoreRef(size_t depth) : fetch_(depth) {}

void CoreRef::reset() { fetch_.reset(); }

void CoreRef::write_imem(uint32_t addr, uint32_t data) {
    fetch_.write(addr, data);
}

void CoreRef::tick() {
    Decoded d = decode(fetch_.inst());
    uint32_t rval1 = rf_.read(d.rs1);
    uint32_t rval2 = rf_.read(d.rs2);
    ExeResult r = execute(fetch_.pc(), d, rval1, rval2);
    rf_.write(r.rfwb_rd, r.rfwb_wen, r.rfwb_wdata);
    fetch_.tick();
}

uint32_t CoreRef::pc() const { return fetch_.pc(); }

uint32_t CoreRef::read_reg(uint8_t rs) const { return rf_.read(rs); }
