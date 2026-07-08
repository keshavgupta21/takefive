.section .text
.global main
main:
    jal   x1, skip1          # x1 = PC+4 = 12; jump to skip1
    addi  x2, x0, 0xFF       # MUST NOT execute
skip1:
    jal   x3, skip2          # x3 = PC+4 = 20; jump to skip2
    addi  x4, x0, 0xFF       # MUST NOT execute
skip2:
    addi  x5, x0, 1          # x5 = 1  (executed)
    jal   x0, skip3          # jump without saving link register
    addi  x6, x0, 0xFF       # MUST NOT execute
skip3:
    addi  x7, x0, 2          # x7 = 2  (executed)
    j     dump_and_exit
