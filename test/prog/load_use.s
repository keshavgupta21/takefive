.section .text
.global main
main:
    lui   x1, 0x80000        # x1 = 0x80000000 (DMEM base)
    addi  x2, x0, 42
    sw    x2, 0(x1)          # mem[0] = 42
    lw    x3, 0(x1)          # x3 = 42
    add   x4, x3, x3         # x4 = 84  (load-use hazard: x3 used immediately after LW)
    addi  x5, x3, 1          # x5 = 43  (load-use hazard: x3 used again)
    addi  x2, x0, 99
    sw    x2, 4(x1)          # mem[4] = 99
    lw    x6, 4(x1)          # x6 = 99
    addi  x7, x6, 1          # x7 = 100  (load-use hazard on x6)
    add   x8, x6, x3         # x8 = 141  (x6 and x3 both bypassed)
    j     dump_and_exit
