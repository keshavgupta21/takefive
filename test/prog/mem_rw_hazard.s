.section .text
.global main
main:
    lui   x1, 0x80000        # x1 = 0x80000000 (DMEM base)
    addi  x2, x0, 0x123
    sw    x2, 0(x1)          # store 0x123
    lw    x3, 0(x1)          # x3 = 0x123  (load from just-stored addr)
    addi  x4, x3, 1          # x4 = 0x124  (load-use hazard)
    sw    x4, 0(x1)          # overwrite same address
    lw    x5, 0(x1)          # x5 = 0x124
    addi  x6, x0, 0x111
    addi  x7, x0, 0x222
    sw    x6, 4(x1)          # mem[4] = 0x111
    sw    x7, 8(x1)          # mem[8] = 0x222
    lw    x8, 4(x1)          # x8 = 0x111
    lw    x9, 8(x1)          # x9 = 0x222
    add   x10, x8, x9        # x10 = 0x333
    j     dump_and_exit
