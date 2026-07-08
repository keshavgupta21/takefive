.section .text
.global main
main:
    addi  x1,  x0, 100       # x1 = 100
    addi  x2,  x0, -1        # x2 = 0xFFFFFFFF
    addi  x3,  x1, -5        # x3 = 95
    andi  x4,  x2, 0xFF      # x4 = 0xFF
    ori   x5,  x0, 0x7FF     # x5 = 0x7FF
    xori  x6,  x2, 0x0F      # x6 = 0xFFFFFFF0
    slti  x7,  x2, 0         # signed: -1 < 0 -> 1
    sltiu x8,  x2, 1         # unsigned: 0xFFFFFFFF < 1 -> 0
    slli  x9,  x1, 3         # x9 = 100 << 3 = 800
    srli  x10, x1, 2         # x10 = 100 >> 2 = 25
    srai  x11, x2, 4         # x11 = -1 >> 4 = -1 (0xFFFFFFFF)
    j     dump_and_exit
