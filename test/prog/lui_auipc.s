.section .text
.global main
main:
    lui   x1, 0xABCDE        # x1 = 0xABCDE000
    lui   x2, 1              # x2 = 0x00001000
    add   x3, x1, x2         # x3 = 0xABCDF000
    auipc x4, 0              # x4 = PC of this instruction
    auipc x5, 0              # x5 = x4 + 4
    sub   x6, x5, x4         # x6 = 4  (consecutive AUIPC differ by exactly 4)
    auipc x7, 1              # x7 = PC + 0x1000
    sub   x8, x7, x5         # x8 = (PC_x7 + 0x1000) - PC_x5
                              #     = (PC_x5 + 8) + 0x1000 - PC_x5 = 0x1008
    j     dump_and_exit
