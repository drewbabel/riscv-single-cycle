        .section .text
        .globl _start
_start:
        addi x1, x0, 7      # counter = 7
        addi x2, x0, 0      # sum = 0
loop:   add  x2, x2, x1     # sum += counter
        addi x1, x1, -1     # counter -= 1
        bne  x1, x0, loop   # counter != 0 -> jump back to loop
        sw   x2, 0(x0)      # dmem[0] = sum
done:   beq  x0, x0, done   # park here
