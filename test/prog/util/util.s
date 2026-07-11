.section .text.start, "ax", @progbits

.global _start
_start:
    lui  sp, 0x80001    # sp = 0x80001000 = top of DMEM (0x80000000 + 4K)
    j    main

.section .text

.global exit
exit:
    sw   x0,  -4(x0)
endloop:
    j    endloop

.global dump_and_exit
dump_and_exit:
    sw   x0,  -256(x0)
    sw   x1,  -252(x0)
    sw   x2,  -248(x0)
    sw   x3,  -244(x0)
    sw   x4,  -240(x0)
    sw   x5,  -236(x0)
    sw   x6,  -232(x0)
    sw   x7,  -228(x0)
    sw   x8,  -224(x0)
    sw   x9,  -220(x0)
    sw   x10, -216(x0)
    sw   x11, -212(x0)
    sw   x12, -208(x0)
    sw   x13, -204(x0)
    sw   x14, -200(x0)
    sw   x15, -196(x0)
    sw   x16, -192(x0)
    sw   x17, -188(x0)
    sw   x18, -184(x0)
    sw   x19, -180(x0)
    sw   x20, -176(x0)
    sw   x21, -172(x0)
    sw   x22, -168(x0)
    sw   x23, -164(x0)
    sw   x24, -160(x0)
    sw   x25, -156(x0)
    sw   x26, -152(x0)
    sw   x27, -148(x0)
    sw   x28, -144(x0)
    sw   x29, -140(x0)
    sw   x30, -136(x0)
    sw   x31, -132(x0)
    j exit
