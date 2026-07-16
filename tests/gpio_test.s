        .section .text
        .globl _start
# Static LED pattern
_start:
        lui  x1, 0x03000       # LED base
        li   x2, 0xABCD
        sw   x2, 0(x1)
park:   jal  x0, park
