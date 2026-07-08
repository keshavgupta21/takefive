.section .text
.global main
main:
    addi  x1,  x0, 1         # x1 = 1
    slli  x2,  x1, 15        # x2 = 0x00008000
    slli  x3,  x1, 31        # x3 = 0x80000000
    srli  x4,  x3, 1         # x4 = 0x40000000
    srli  x5,  x3, 31        # x5 = 1
    srai  x6,  x3, 1         # x6 = 0xC0000000  (arithmetic: sign bit extended)
    srai  x7,  x3, 31        # x7 = 0xFFFFFFFF
    addi  x8,  x0, -1        # x8 = 0xFFFFFFFF
    srli  x9,  x8, 1         # x9 = 0x7FFFFFFF  (logical shift)
    srai  x10, x8, 1         # x10 = 0xFFFFFFFF  (arithmetic shift)
    addi  x11, x0, 4
    sll   x12, x1, x11       # x12 = 1 << 4 = 16
    srl   x13, x3, x11       # x13 = 0x80000000 >> 4 = 0x08000000
    sra   x14, x3, x11       # x14 = 0x80000000 >>> 4 = 0xF8000000
    j     dump_and_exit
