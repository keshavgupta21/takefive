#pragma once

static inline __attribute__((always_inline)) void putc(char c) {
    *(volatile unsigned int *)0xFFFFFFF8u = (unsigned int)(unsigned char)c;
}

static inline __attribute__((always_inline)) void puts(const char *s) {
    const unsigned int *w = (const unsigned int *)(const void *)s;
    while (1) {
        unsigned int v = *w++;
        unsigned int b;
        b =  v        & 0xFFu; if (!b) return; putc((char)b);
        b = (v >>  8) & 0xFFu; if (!b) return; putc((char)b);
        b = (v >> 16) & 0xFFu; if (!b) return; putc((char)b);
        b = (v >> 24) & 0xFFu; if (!b) return; putc((char)b);
    }
}

static inline __attribute__((always_inline, noreturn)) void exit(void) {
    asm volatile("sw x0, -4(x0)");
    __builtin_unreachable();
}

static inline __attribute__((always_inline, noreturn)) void dump_and_exit(void) {
    asm volatile(
        "sw x0,  -256(x0)\n"
        "sw x1,  -252(x0)\n"
        "sw x2,  -248(x0)\n"
        "sw x3,  -244(x0)\n"
        "sw x4,  -240(x0)\n"
        "sw x5,  -236(x0)\n"
        "sw x6,  -232(x0)\n"
        "sw x7,  -228(x0)\n"
        "sw x8,  -224(x0)\n"
        "sw x9,  -220(x0)\n"
        "sw x10, -216(x0)\n"
        "sw x11, -212(x0)\n"
        "sw x12, -208(x0)\n"
        "sw x13, -204(x0)\n"
        "sw x14, -200(x0)\n"
        "sw x15, -196(x0)\n"
        "sw x16, -192(x0)\n"
        "sw x17, -188(x0)\n"
        "sw x18, -184(x0)\n"
        "sw x19, -180(x0)\n"
        "sw x20, -176(x0)\n"
        "sw x21, -172(x0)\n"
        "sw x22, -168(x0)\n"
        "sw x23, -164(x0)\n"
        "sw x24, -160(x0)\n"
        "sw x25, -156(x0)\n"
        "sw x26, -152(x0)\n"
        "sw x27, -148(x0)\n"
        "sw x28, -144(x0)\n"
        "sw x29, -140(x0)\n"
        "sw x30, -136(x0)\n"
        "sw x31, -132(x0)\n"
        "sw x0,    -4(x0)\n"
    );
    __builtin_unreachable();
}
