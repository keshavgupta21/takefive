.section .text
.global main
main:
    lui   x1, 0x80000        # x1 = 0x80000000 (DMEM base)
    addi  x2, x0, 7
    addi  x3, x0, 3
    sw    x2, 0(x1)          # mem[0] = 7
    sw    x3, 4(x1)          # mem[4] = 3
    add   x4, x2, x3         # x4 = 10  (ALU while stores in flight)
    lw    x5, 0(x1)          # x5 = 7
    lw    x6, 4(x1)          # x6 = 3
    add   x7, x5, x6         # x7 = 10  (load-use + bypass)
    sub   x8, x4, x3         # x8 = 7   (EX->WB bypass on x4)
    beq   x7, x4, eq_ok      # 10 == 10 -> taken
    addi  x9, x0, 0xFF       # MUST NOT execute
eq_ok:
    addi  x9, x0, 1          # x9 = 1
    slli  x10, x7, 2         # x10 = 10 << 2 = 40
    j     dump_and_exit
