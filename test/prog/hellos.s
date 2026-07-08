.section .text
.global main
main:
    lui  x1, 0x01020
    addi x1, x1, 0x304
    j    dump_and_exit
