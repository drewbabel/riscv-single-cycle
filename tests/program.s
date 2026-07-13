        .section .text
        .globl _start
_start:
        addi x1, x0, 5      # x1 = 5
        addi x2, x0, 3      # x2 = 3
        add  x3, x1, x2     # x3 = 8
        sub  x4, x3, x2     # x4 = 5
        sw   x3, 0(x0)      # dmem[0] = 8
        lw   x5, 0(x0)      # x5 = 8
done:   beq  x0, x0, done   # park here
