.section .text
.global main
main:
    addi  x1, x0, 5
    addi  x2, x0, 5
    addi  x3, x0, -1         # x3 = 0xFFFFFFFF
    beq   x1, x2, beq_ok     # 5 == 5 -> taken
    j     dump_and_exit       # fail path: x4 stays 0
beq_ok:
    bne   x1, x3, bne_ok     # 5 != -1 -> taken
    j     dump_and_exit
bne_ok:
    blt   x3, x1, blt_ok     # -1 < 5 (signed) -> taken
    j     dump_and_exit
blt_ok:
    bge   x1, x1, bge_ok     # 5 >= 5 -> taken
    j     dump_and_exit
bge_ok:
    bltu  x1, x3, bltu_ok    # 5 < 0xFFFFFFFF (unsigned) -> taken
    j     dump_and_exit
bltu_ok:
    bgeu  x3, x1, bgeu_ok    # 0xFFFFFFFF >= 5 (unsigned) -> taken
    j     dump_and_exit
bgeu_ok:
    addi  x4, x0, 1          # x4 = 1: all 6 branches taken correctly
    j     dump_and_exit
