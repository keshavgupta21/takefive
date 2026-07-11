`include "common.svh"

package takefive_pkg;

    // ---------------- Instruction Encoding ----------------

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

    // ---------------- Processor Types ----------------

    typedef struct packed {
        opc_t        opc;
        logic [4:0]  rd;
        logic [4:0]  rs1;
        logic [4:0]  rs2;
        logic        rs2_vld;
        logic [2:0]  funct3;
        f7_t         funct7;
        logic [31:0] imm;
    } inst_t;

    typedef struct packed {
        logic [4:0] rs1;
        logic [4:0] rs2;
    } rf_rd_req_t;

    typedef struct packed {
        logic [31:0] rval1;
        logic [31:0] rval2;
    } rf_rd_rsp_t;

    typedef struct packed {
        logic [4:0]  rd;
        logic        wen;
        logic [31:0] wdata;
    } rf_wr_req_t;

    typedef struct packed {
        logic        vld;
        logic [31:0] pc;
        logic [31:0] inst;
    } f2d_t;

    typedef struct packed {
        logic        vld;
        logic [31:0] pc;
        inst_t       inst;
    } d2r_t;

    typedef struct packed {
        logic        vld;
        logic [31:0] pc;
        inst_t       inst;
        rf_rd_rsp_t  rvals;
    } r2e_t;

    typedef struct packed {
        logic        vld;
        logic [31:0] pc;
        inst_t       inst;
        rf_rd_rsp_t  rvals;
        logic [31:0] alu_out;
    } e2w_t;

    typedef struct packed {
        logic        annul;
        logic [31:0] pc;
        logic [31:0] nxt_pc;
    } annul_t;

    typedef struct packed {
        logic        vld;
        logic        wen;
        logic [31:0] addr;
        logic [31:0] data;
        logic [31:0] uid;
    } mem_req_t;

    typedef struct packed {
        logic        vld;
        logic [31:0] data;
        logic [31:0] uid;
    } mem_rsp_t;

    // ---------------- MMIO Map ----------------

    // Core-side word indices (addr[7:2] within 0xFFFFFF00 space)
    parameter MMIO_DATA_WORDS  = 8'h80;
    parameter MMIO_ADDR_RLEVEL = 8'hF4;
    parameter MMIO_ADDR_STREAM = 8'hF8;
    parameter MMIO_ADDR_EXIT   = 8'hFC;

    // AXI-Lite control register byte addresses (saxil slave)
    parameter CFG_IMEM_BASE  = 8'h80;
    parameter CFG_IMEM_BOUND = 8'h84;
    parameter CFG_DMEM_BASE  = 8'h88;
    parameter CFG_DMEM_BOUND = 8'h8C;

    // ---------------- Cache Types ----------------

    parameter DMEM_VADDR  = 32'h80000000;
    parameter CL_WORDS    = 16;
    parameter CACHE_DEPTH = 16;
    parameter CL_BITS     = $clog2(CL_WORDS);
    parameter IDX_BITS    = $clog2(CACHE_DEPTH);
    parameter TAG_BITS    = 32 - IDX_BITS - CL_BITS - 2;

    typedef struct packed {
        logic [TAG_BITS-1:0] tag;
        logic [IDX_BITS-1:0] idx;
        logic [CL_BITS-1:0]  wo;
        logic [1:0]          bo;
    } addr_t;

    typedef struct packed {
        logic                      dirty;
        logic [TAG_BITS-1:0]       tag;
        logic [CL_WORDS-1:0][31:0] words;
    } cacheline_t;

    typedef struct packed {
        logic                      vld;
        logic [31:0]               addr;
        logic                      wen;
        logic [CL_WORDS-1:0][31:0] data;
    } dram_req_t;

    typedef struct packed {
        logic                      vld;
        logic [CL_WORDS-1:0][31:0] data;
    } dram_rsp_t;

endpackage
