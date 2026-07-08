.section .text
.global main
main:
    addi  x1, x0, 0
    beq   x0, x0, t1         # always taken; must annul speculatively-fetched instrs
    addi  x2, x0, 0xFF       # MUST NOT execute
    addi  x3, x0, 0xFF       # MUST NOT execute
t1:
    addi  x4, x0, 1          # x4 = 1  (executed)
    jal   x0, t2             # unconditional jump; must annul speculative fetch
    addi  x5, x0, 0xFF       # MUST NOT execute
    addi  x6, x0, 0xFF       # MUST NOT execute
t2:
    addi  x7, x0, 2          # x7 = 2  (executed)
    bne   x0, x0, t3         # 0 != 0 -> NOT taken; next instr must execute
    addi  x8, x0, 3          # x8 = 3  (executed; branch not taken)
t3:
    j     dump_and_exit
