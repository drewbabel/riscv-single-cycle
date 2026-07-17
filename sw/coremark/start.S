.section .init
.global _start
_start:
    .option push
    .option norelax
    la    gp, __global_pointer$
    .option pop
    la    sp, _stack_top

    /* zero bss */
    la    t0, _bss_start
    la    t1, _bss_end
1:  bge   t0, t1, 2f
    sw    zero, 0(t0)
    addi  t0, t0, 4
    j     1b
2:
    call  main
    li    t0, 0x03000000
    li    t1, 0xC0DE
    sw    t1, 0(t0)
3:  j     3b
