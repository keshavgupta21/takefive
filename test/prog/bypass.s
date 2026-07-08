.section .text
.global main
main:
    addi  x1,  x0, 10
    addi  x2,  x0, 5
    add   x3,  x1, x2        # x3 = 15
    add   x4,  x3, x2        # x4 = 20  (EX->EX bypass on rs1=x3)
    add   x5,  x1, x2        # x5 = 15
    add   x6,  x2, x5        # x6 = 20  (EX->EX bypass on rs2=x5)
    add   x7,  x1, x2        # x7 = 15
    add   x8,  x7, x7        # x8 = 30  (EX->EX bypass on both rs1 and rs2=x7)
    add   x9,  x1, x2        # x9 = 15
    addi  x10, x0, 1         # gap instruction
    add   x11, x9, x2        # x11 = 20  (WB->EX bypass: x9 is 2 cycles old)
    j     dump_and_exit
