interface f2d_intf;

    logic [31:0] pc;
    logic [31:0] inst;

    modport f (output pc, inst);
    modport d (input  pc, inst);

endinterface
