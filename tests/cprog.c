#define M ((volatile int *)0x80008000)

void _start(void) {
    int a = 15, b = 4;
    M[0] = a + b;
    M[1] = a - b;
    M[2] = a & b;
    M[3] = a | b;
    M[4] = a ^ b;
    M[5] = a << b;
    M[6] = a >> 1;
    M[7] = (a < b);
    for (;;) {}
}
