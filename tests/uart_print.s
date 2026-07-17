        .section .text
        .globl _start
# Print over serial
_start:
        li   s0, 0x04000000
        la   s1, msg
loop:
        lbu  a0, 0(s1)
        beq  a0, x0, done
poll:
        lw   t0, 4(s0)
        andi t0, t0, 1
        beq  t0, x0, poll
        sw   a0, 0(s0)
        addi s1, s1, 1
        j    loop
done:
        li   x28, 1
park:
        j    park

        .balign 4
msg:
        .asciz "OK\n"
