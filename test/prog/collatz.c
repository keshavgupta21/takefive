#include "util/util.h"

static void collatz(unsigned int n) {
    unsigned int cur = n;
    unsigned int max = n;
    while (cur != 1u) {
        if (cur & 1u) cur = 3u * cur + 1u;
        else          cur >>= 1;
        if (cur > max) max = cur;
    }
    puth(n);
    puts(": yes, ");
    puth(max);
    putc('\n');
}

void main(void) {
    unsigned int n;
    for (n = 1u; n <= 1024u; n++)
        collatz(n);
    dump_and_exit();
}
