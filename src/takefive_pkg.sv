`include "common.svh"

package takefive_pkg;
    typedef struct packed {
        logic        vld;
        logic [31:0] pc;
        logic [31:0] inst;
    } f2d_t;

    typedef enum logic [6:0] {
        OPC_LOAD   = 7'b0000011,
        OPC_FENCE  = 7'b0001111,
        OPC_IMM    = 7'b0010011,
        OPC_AUIPC  = 7'b0010111,
        OPC_STORE  = 7'b0100011,
        OPC_REG    = 7'b0110011,
        OPC_LUI    = 7'b0110111,
        OPC_BRANCH = 7'b1100011,
        OPC_JALR   = 7'b1100111,
        OPC_JAL    = 7'b1101111,
        OPC_SYSTEM = 7'b1110011
    } opc_t;

    typedef enum logic [2:0] {
        F3_ADD  = 3'b000,
        F3_SLL  = 3'b001,
        F3_SLT  = 3'b010,
        F3_SLTU = 3'b011,
        F3_XOR  = 3'b100,
        F3_SR   = 3'b101,
        F3_OR   = 3'b110,
        F3_AND  = 3'b111
    } f3_alu_t;

    typedef enum logic [2:0] {
        F3_B  = 3'b000,
        F3_H  = 3'b001,
        F3_W  = 3'b010,
        F3_BU = 3'b100,
        F3_HU = 3'b101
    } f3_mem_t;

    typedef enum logic [2:0] {
        F3_BEQ  = 3'b000,
        F3_BNE  = 3'b001,
        F3_BLT  = 3'b100,
        F3_BGE  = 3'b101,
        F3_BLTU = 3'b110,
        F3_BGEU = 3'b111
    } f3_br_t;

    typedef enum logic [6:0] {
        F7_BASE = 7'b0000000,
        F7_ALT  = 7'b0100000
    } f7_t;

    typedef struct packed {
        opc_t        opc;
        logic [4:0]  rd;
        logic [4:0]  rs1;
        logic [4:0]  rs2;
        logic [2:0]  funct3;
        f7_t         funct7;
        logic [31:0] imm;
    } inst_t;

    typedef struct packed {
        logic [31:0] rval1;
        logic [31:0] rval2;
    } rvals_t;

    typedef struct packed {
        logic        vld;
        logic [31:0] pc;
        inst_t       inst;
    } d2r_t;

    typedef struct packed {
        logic        vld;
        logic [31:0] pc;
        inst_t       inst;
        rvals_t      rvals;
    } r2e_t;

    typedef struct packed {
        logic [4:0]  rd;
        logic        wen;
        logic [31:0] wdata;
    } rfwb_t;

    typedef struct packed {
        logic        vld;
        logic [31:0] pc;
        logic [31:0] nxt_pc;
    } nxt_pc_t;

    typedef struct packed {
        logic        vld;
        logic [31:0] addr;
        logic        wen;
        logic [31:0] data;
    } mem_req_t;

    typedef struct packed {
        logic        vld;
        logic [31:0] addr;
        logic [31:0] data;
    } mem_rsp_t;

endpackage
