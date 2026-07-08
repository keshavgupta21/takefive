.section .text
.global main
main:
    addi  x1, x0, 5
    addi  x2, x0, 10
    addi  x3, x0, -1         # x3 = 0xFFFFFFFF
    beq   x1, x2, skip1      # 5 != 10 -> NOT taken
    addi  x4, x0, 1          # x4 = 1  (executed)
skip1:
    bne   x1, x1, skip2      # 5 == 5 -> NOT taken
    addi  x5, x0, 2          # x5 = 2  (executed)
skip2:
    blt   x2, x1, skip3      # 10 < 5 -> NOT taken
    addi  x6, x0, 3          # x6 = 3  (executed)
skip3:
    bge   x1, x2, skip4      # 5 >= 10 -> NOT taken
    addi  x7, x0, 4          # x7 = 4  (executed)
skip4:
    bltu  x3, x1, skip5      # 0xFFFFFFFF < 5 (unsigned) -> NOT taken
    addi  x8, x0, 5          # x8 = 5  (executed)
skip5:
    bgeu  x1, x3, done       # 5 >= 0xFFFFFFFF (unsigned) -> NOT taken
    addi  x9, x0, 6          # x9 = 6  (executed)
done:
    j     dump_and_exit
