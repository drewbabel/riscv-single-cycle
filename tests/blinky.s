        .section .text
        .globl _start
# Binary counter on LEDs
_start:
        lui  x1, 0x03000        # LED base
        addi x2, x0, 0          # counter
loop:
        sw   x2, 0(x1)          # LEDs = counter
        addi x2, x2, 1
        lui  x3, 0x400          # delay count
delay:
        addi x3, x3, -1
        bne  x3, x0, delay
        jal  x0, loop
