.section .text
.global main
main:
    addi  x1,  x0, 10        # x1 = 10
    addi  x2,  x0, -1        # x2 = 0xFFFFFFFF
    slt   x3,  x2, x1        # signed:   -1 < 10 -> 1
    slt   x4,  x1, x2        # signed:   10 < -1 -> 0
    sltu  x5,  x1, x2        # unsigned: 10 < 0xFFFFFFFF -> 1
    sltu  x6,  x2, x1        # unsigned: 0xFFFFFFFF < 10 -> 0
    slti  x7,  x2, 0         # signed:   -1 < 0 -> 1
    slti  x8,  x1, 10        # signed:   10 < 10 -> 0
    sltiu x9,  x1, 11        # unsigned: 10 < 11 -> 1
    sltiu x10, x2, 1         # unsigned: 0xFFFFFFFF < 1 -> 0
    j     dump_and_exit
