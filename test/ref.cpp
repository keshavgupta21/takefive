#include "ref.h"
#include <cstring>
#include <deque>
#include <fstream>
#include <iomanip>
#include <sstream>

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

static const char *reg_name(uint8_t r) {
    static const char *names[] = {
        "x0", "x1", "x2", "x3", "x4", "x5", "x6", "x7",
        "x8", "x9", "x10","x11","x12","x13","x14","x15",
        "x16","x17","x18","x19","x20","x21","x22","x23",
        "x24","x25","x26","x27","x28","x29","x30","x31"
    };
    return names[r & 0x1F];
}

std::string disasm(const Decoded& d) {
    std::ostringstream os;
    if (!d.vld) { os << "<invalid>"; return os.str(); }

    auto imm = [&]() -> int32_t { return (int32_t)d.imm; };

    switch (d.opcode) {
        case 0x33: { // R-type
            const char *mn = "???";
            switch (d.funct3) {
                case 0: mn = d.funct7 ? "SUB" : "ADD"; break;
                case 1: mn = "SLL";  break;
                case 2: mn = "SLT";  break;
                case 3: mn = "SLTU"; break;
                case 4: mn = "XOR";  break;
                case 5: mn = d.funct7 ? "SRA" : "SRL"; break;
                case 6: mn = "OR";   break;
                case 7: mn = "AND";  break;
            }
            os << mn << " " << reg_name(d.rd) << ", "
               << reg_name(d.rs1) << ", " << reg_name(d.rs2);
            break;
        }
        case 0x13: { // I-type ALU
            const char *mn = "???";
            switch (d.funct3) {
                case 0: mn = "ADDI";  break;
                case 1: mn = "SLLI";  break;
                case 2: mn = "SLTI";  break;
                case 3: mn = "SLTIU"; break;
                case 4: mn = "XORI";  break;
                case 5: mn = d.funct7 ? "SRAI" : "SRLI"; break;
                case 6: mn = "ORI";   break;
                case 7: mn = "ANDI";  break;
            }
            if (d.funct3 == 1 || d.funct3 == 5)
                os << mn << " " << reg_name(d.rd) << ", "
                   << reg_name(d.rs1) << ", " << (d.imm & 0x1F);
            else
                os << mn << " " << reg_name(d.rd) << ", "
                   << reg_name(d.rs1) << ", " << imm();
            break;
        }
        case 0x03: // LW
            os << "LW " << reg_name(d.rd) << ", "
               << imm() << "(" << reg_name(d.rs1) << ")";
            break;
        case 0x23: // SW
            os << "SW " << reg_name(d.rs2) << ", "
               << imm() << "(" << reg_name(d.rs1) << ")";
            break;
        case 0x63: { // Branch
            const char *mn = "???";
            switch (d.funct3) {
                case 0: mn = "BEQ";  break;
                case 1: mn = "BNE";  break;
                case 4: mn = "BLT";  break;
                case 5: mn = "BGE";  break;
                case 6: mn = "BLTU"; break;
                case 7: mn = "BGEU"; break;
            }
            os << mn << " " << reg_name(d.rs1) << ", "
               << reg_name(d.rs2) << ", " << imm();
            break;
        }
        case 0x37: // LUI
            os << "LUI " << reg_name(d.rd) << ", 0x"
               << std::hex << (d.imm >> 12) << std::dec;
            break;
        case 0x17: // AUIPC
            os << "AUIPC " << reg_name(d.rd) << ", 0x"
               << std::hex << (d.imm >> 12) << std::dec;
            break;
        case 0x6F: // JAL
            os << "JAL " << reg_name(d.rd) << ", " << imm();
            break;
        case 0x67: // JALR
            os << "JALR " << reg_name(d.rd) << ", "
               << reg_name(d.rs1) << ", " << imm();
            break;
        case 0x0F: // FENCE
            os << "FENCE";
            break;
        case 0x73: // ECALL/EBREAK
            os << (d.imm ? "EBREAK" : "ECALL");
            break;
        default:
            os << "<unknown 0x" << std::hex << (int)d.opcode << ">";
            break;
    }
    return os.str();
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
        case 0x03: // Loads (word only)
            return funct3 == 2;
        case 0x23: // Stores (word only)
            return funct3 == 2;
        case 0x63: // Branches
            return funct3 == 0 || funct3 == 1 || funct3 == 4
                || funct3 == 5 || funct3 == 6 || funct3 == 7;
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
    {0x63, 0, 0x00}, {0x63, 1, 0x00}, {0x63, 4, 0x00},
    {0x63, 5, 0x00}, {0x63, 6, 0x00}, {0x63, 7, 0x00},
    {0x03, 2, 0x00}, {0x23, 2, 0x00},
};
const int N_INST_TYPES = sizeof(INST_TYPES) / sizeof(INST_TYPES[0]);

static bool is_branch_or_jump(uint8_t opc) {
    return opc == 0x63 || opc == 0x6F || opc == 0x67;
}

static bool uses_rs1(uint8_t opc) {
    return opc == 0x33 || opc == 0x13 || opc == 0x03 || opc == 0x23
        || opc == 0x63 || opc == 0x67;
}

static bool uses_rs2(uint8_t opc) {
    return opc == 0x33 || opc == 0x23 || opc == 0x63;
}

static std::deque<uint8_t> recent_rds;

static bool is_mem_op(uint8_t opc) {
    return opc == 0x03 || opc == 0x23;
}

Decoded gen_random_inst(std::mt19937 &rng, int hazard_dist, bool no_branches,
                        bool no_mem) {
    std::uniform_int_distribution<uint32_t> val_dist;
    std::uniform_int_distribution<int>      type_dist(0, N_INST_TYPES - 1);
    std::uniform_int_distribution<uint8_t>  reg_dist(0, 31);

    for (;;) {
        const InstType &t = INST_TYPES[type_dist(rng)];

        if (no_branches && is_branch_or_jump(t.opc)) continue;
        if (no_mem && is_mem_op(t.opc)) continue;

        uint8_t rd  = reg_dist(rng);
        uint8_t rs1 = reg_dist(rng);
        uint8_t rs2 = reg_dist(rng);

        if (hazard_dist > 0) {
            bool hazard = false;
            int depth = std::min(hazard_dist, (int)recent_rds.size());
            for (int i = 0; i < depth; i++) {
                uint8_t prev_rd = recent_rds[recent_rds.size() - 1 - i];
                if (prev_rd == 0) continue;
                if (uses_rs1(t.opc) && rs1 == prev_rd) { hazard = true; break; }
                if (uses_rs2(t.opc) && rs2 == prev_rd) { hazard = true; break; }
            }
            if (hazard) continue;
        }

        if (hazard_dist > 0) {
            recent_rds.push_back(rd);
            if ((int)recent_rds.size() > hazard_dist) recent_rds.pop_front();
        }

        return make_inst(true, t.opc, rd, rs1, rs2, t.f3, t.f7, val_dist(rng));
    }
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
                  uint32_t rval1, uint32_t rval2, uint32_t dmem_data) {
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
        case 0x03: // LOAD
            r.rfwb_wen   = true;
            r.rfwb_wdata = dmem_data;
            break;
        default:
            break;
    }

    return r;
}

// ---- NxtPcResult ----

bool NxtPcResult::operator==(const NxtPcResult& o) const {
    return vld == o.vld && pc == o.pc && nxt_pc == o.nxt_pc;
}

bool NxtPcResult::operator!=(const NxtPcResult& o) const { return !(*this == o); }

std::ostream& operator<<(std::ostream& os, const NxtPcResult& r) {
    os << "vld=" << r.vld
       << " pc=0x" << std::hex << std::setfill('0')
       << std::setw(8) << r.pc
       << " nxt_pc=0x" << std::setw(8) << r.nxt_pc << std::dec;
    return os;
}

NxtPcResult branch_eval(uint32_t pc, const Decoded& inst,
                        uint32_t rval1, uint32_t rval2) {
    NxtPcResult r;
    r.vld    = false;
    r.pc     = pc;
    r.nxt_pc = 0;

    if (!inst.vld) return r;

    switch (inst.opcode) {
        case 0x63: { // BRANCH
            bool cond = false;
            switch (inst.funct3) {
                case 0: cond = (rval1 == rval2); break;
                case 1: cond = (rval1 != rval2); break;
                case 4: cond = ((int32_t)rval1 <  (int32_t)rval2); break;
                case 5: cond = ((int32_t)rval1 >= (int32_t)rval2); break;
                case 6: cond = (rval1 <  rval2); break;
                case 7: cond = (rval1 >= rval2); break;
                default: break;
            }
            r.vld    = cond;
            r.nxt_pc = pc + inst.imm;
            break;
        }
        case 0x6F: // JAL
            r.vld    = true;
            r.nxt_pc = pc + inst.imm;
            break;
        case 0x67: // JALR
            r.vld    = true;
            r.nxt_pc = (rval1 + inst.imm) & ~1u;
            break;
        default:
            break;
    }

    return r;
}

// ---- RfRef ----

RfRef::RfRef() {
    std::fill(std::begin(regs_), std::end(regs_), 0);
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

void FetchRef::tick(bool nxt_vld, uint32_t nxt) {
    if (nxt_vld) pc_ = nxt;
    else         pc_ += 4;
}

uint32_t FetchRef::pc() const { return pc_; }

uint32_t FetchRef::inst() const { return mem_[(pc_ >> 2) % mem_.size()]; }

// ---- CoreRef ----

CoreRef::CoreRef() : pc_(0), insns_retired_(0) {
    std::memset(imem_, 0, sizeof(imem_));
    std::memset(dmem_, 0, sizeof(dmem_));
    std::memset(mmio_, 0, sizeof(mmio_));
}

bool CoreRef::load_imem(const std::string& path) {
    std::ifstream f(path);
    if (!f) return false;
    for (int i = 0; i < DRAM_WORDS; i++)
        if (!(f >> std::hex >> imem_[i])) break;
    return true;
}

bool CoreRef::load_dmem(const std::string& path) {
    std::ifstream f(path);
    if (!f) return false;
    for (int i = 0; i < DRAM_WORDS; i++)
        if (!(f >> std::hex >> dmem_[i])) break;
    return true;
}

uint32_t CoreRef::reg(int r)       const { return rf_.read(r); }
uint32_t CoreRef::pc()             const { return pc_; }
uint32_t CoreRef::mmio(int i)      const { return mmio_[i]; }
uint64_t CoreRef::insns_retired()  const { return insns_retired_; }

bool CoreRef::step() {
    uint32_t idx   = pc_ >> 2;
    uint32_t instr = (idx < (uint32_t)DRAM_WORDS) ? imem_[idx] : 0;

    Decoded  d     = decode(instr);
    uint32_t rval1 = rf_.read(d.rs1);
    uint32_t rval2 = rf_.read(d.rs2);

    uint32_t dmem_data = 0;
    if (d.vld) {
        if (d.opcode == 0x03) {                          // LOAD
            uint32_t addr = rval1 + (int32_t)d.imm;
            if (addr >= 0xFFFFFF00u) {
                dmem_data = mmio_[(addr & 0xFFu) >> 2];
            } else if (addr >= 0x80000000u) {
                uint32_t widx = (addr - 0x80000000u) >> 2;
                if (widx < (uint32_t)DRAM_WORDS) dmem_data = dmem_[widx];
            }
        } else if (d.opcode == 0x23) {                   // STORE
            uint32_t addr = rval1 + (int32_t)d.imm;
            if (addr >= 0xFFFFFF00u) {
                if (addr == 0xFFFFFFFC) return true;     // exit
                mmio_[(addr & 0xFFu) >> 2] = rval2;
            } else if (addr >= 0x80000000u) {
                uint32_t widx = (addr - 0x80000000u) >> 2;
                if (widx < (uint32_t)DRAM_WORDS) dmem_[widx] = rval2;
            }
        }
    }

    ExeResult    res = execute(pc_, d, rval1, rval2, dmem_data);
    rf_.write(res.rfwb_rd, res.rfwb_wen, res.rfwb_wdata);

    NxtPcResult npc = branch_eval(pc_, d, rval1, rval2);
    pc_ = npc.vld ? npc.nxt_pc : pc_ + 4;
    return false;
}

bool CoreRef::run(int max_steps) {
    insns_retired_ = 0;
    for (int i = 0; i < max_steps; i++) {
        insns_retired_++;
        if (step()) return true;
    }
    return false;
}
