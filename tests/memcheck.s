.globl _start
_start:
    li   s0, 0x03000000       # LED base
    li   s1, 0x00001000       # data base
    li   s2, 2000             # word count

    li   t6, 0x0003           # breadcrumb: running
    sw   t6, 0(s0)

    li   t0, 0                # fill mem[base+i*4]=i
1:  slli t1, t0, 2
    add  t2, s1, t1
    sw   t0, 0(t2)
    addi t0, t0, 1
    blt  t0, s2, 1b

    li   t0, 0                # verify readback==i
2:  slli t1, t0, 2
    add  t2, s1, t1
    lw   t3, 0(t2)
    bne  t3, t0, fail
    addi t0, t0, 1
    blt  t0, s2, 2b

    li   t6, 0xFFFF           # all correct
    sw   t6, 0(s0)
3:  j    3b

fail:                         # LED15 + failing index
    li   t4, 0x8000
    or   t4, t4, t0
    sw   t4, 0(s0)
4:  j    4b
