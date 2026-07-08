.section .text
.global main
main:
    addi  x1,  x0, 10        # x1 = 10
    addi  x2,  x0, -3        # x2 = -3  (0xFFFFFFFD)
    add   x3,  x1, x2        # x3 = 7
    sub   x4,  x1, x2        # x4 = 13
    and   x5,  x1, x2        # x5 = 8   (0b1010 & 0xFFFFFFFD)
    or    x6,  x1, x2        # x6 = 0xFFFFFFFF
    xor   x7,  x1, x2        # x7 = 0xFFFFFFF7
    sll   x8,  x1, x2        # shamt = x2 & 0x1F = 29; x8 = 10 << 29 = 0x40000000
    srl   x9,  x2, x1        # x9 = 0xFFFFFFFD >> 10 = 0x003FFFFF
    sra   x10, x2, x1        # x10 = -3 >> 10 = -1 = 0xFFFFFFFF
    slt   x11, x2, x1        # signed: -3 < 10 -> 1
    sltu  x12, x2, x1        # unsigned: 0xFFFFFFFD < 10 -> 0
    j     dump_and_exit
