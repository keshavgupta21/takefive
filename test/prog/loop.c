#include "util/util.h"

void main(void) {
    unsigned int n = 0, m = 0;
    for (int i = 0; i < 1024u; i++) {
        n++; asm volatile("" : "+r"(n));
        m++; asm volatile("" : "+r"(m));
        n++; asm volatile("" : "+r"(n));
        m++; asm volatile("" : "+r"(m));
        n++; asm volatile("" : "+r"(n));
        m++; asm volatile("" : "+r"(m));
        n++; asm volatile("" : "+r"(n));
        m++; asm volatile("" : "+r"(m));
        n++; asm volatile("" : "+r"(n));
        m++; asm volatile("" : "+r"(m));
        n++; asm volatile("" : "+r"(n));
        m++; asm volatile("" : "+r"(m));
        n++; asm volatile("" : "+r"(n));
        m++; asm volatile("" : "+r"(m));
        n++; asm volatile("" : "+r"(n));
        m++; asm volatile("" : "+r"(m));
    }
    dump_and_exit();
}
