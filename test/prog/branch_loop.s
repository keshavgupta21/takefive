.section .text
.global main
main:
    addi  x1, x0, 0          # i = 0
    addi  x2, x0, 5          # limit = 5
    addi  x3, x0, 1          # step = 1
    addi  x4, x0, 0          # sum = 0
loop1:
    add   x4, x4, x1         # sum += i
    add   x1, x1, x3         # i++
    blt   x1, x2, loop1      # while i < 5;  result: x1=5, x4=0+1+2+3+4=10
    addi  x5, x0, 3
    addi  x6, x0, 0
loop2:
    add   x6, x6, x5         # x6 += counter
    addi  x5, x5, -1         # counter--
    bne   x5, x0, loop2      # while counter != 0;  result: x6=3+2+1=6
    j     dump_and_exit
