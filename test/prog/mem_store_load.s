.section .text
.global main
main:
    lui   x1, 0x80000        # x1 = 0x80000000 (DMEM base)
    addi  x2, x0, 0x100
    addi  x3, x0, 0x200
    addi  x4, x0, 0x300
    sw    x2, 0(x1)          # mem[0] = 0x100
    sw    x3, 4(x1)          # mem[4] = 0x200
    sw    x4, 8(x1)          # mem[8] = 0x300
    lw    x5, 0(x1)          # x5 = 0x100
    lw    x6, 4(x1)          # x6 = 0x200
    lw    x7, 8(x1)          # x7 = 0x300
    add   x8, x5, x6         # x8 = 0x300
    add   x9, x8, x7         # x9 = 0x600
    sub   x10, x9, x2        # x10 = 0x500
    j     dump_and_exit
