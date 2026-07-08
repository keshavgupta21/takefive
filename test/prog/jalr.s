.section .text
.global main
main:
    jal   x1, func           # x1 = return addr; call func
    addi  x2, x0, 1          # x2 = 1  (executed after return)
    j     done

func:
    addi  x3, x0, 42         # x3 = 42
    jalr  x0, x1, 0          # return via link register
    addi  x4, x0, 0xFF       # MUST NOT execute

done:
    auipc x5, 0              # x5 = PC_done
    addi  x5, x5, 20         # x5 = PC_done + 20  (5 instructions ahead)
    jalr  x6, x5, 0          # x6 = PC_done+8; jump to PC_done+20
    addi  x7, x0, 0xFF       # MUST NOT execute  (PC_done+12)
    addi  x8, x0, 0xFF       # MUST NOT execute  (PC_done+16)
    addi  x9, x0, 1          # x9 = 1  (jump target at PC_done+20)
    j     dump_and_exit
