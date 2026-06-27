`include "common.svh"

package takefive_pkg;

    typedef struct packed {
        logic        valid;
        logic [6:0]  opc;
        logic [4:0]  rd;
        logic [4:0]  rs1;
        logic [4:0]  rs2;
        logic [2:0]  funct3;
        logic [6:0]  funct7;
        logic [31:0] imm;
    } inst_t;

endpackage
