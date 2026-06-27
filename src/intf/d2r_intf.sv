`include "common.svh"
interface d2r_intf;

    logic [31:0]          pc;
    takefive_pkg::inst_t  inst;

    modport d (output pc, inst);
    modport r (input  pc, inst);

endinterface
