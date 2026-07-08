#include "util/util.h"

int main(void) {
    volatile int x = 0x01020304;
    dump_and_exit();
}
