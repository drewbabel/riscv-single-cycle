        .section .text
        .globl _start
_start:
        la    t0, handler
        csrw  mtvec, t0

        li    t1, 0x40          # aligned data word
        li    t2, 0xAAAA
        sw    t2, 0(t1)         # baseline: word[0x40] = 0x0000AAAA

        li    t3, 0xBBBB
        sh    t3, 1(t1)         # misaligned store -> traps; must be annulled
after:
        lw    t4, 0(t1)         # read the word back
        li    t5, 0xAAAA
        bne   t4, t5, fail      # changed -> the trapped store still wrote

        li    x28, 1            # PASS: store annulled and handler returned cleanly
done:   beq   x0, x0, done
fail:
        li    x28, 0xdead
floop:  beq   x0, x0, floop

handler:
        csrr  t6, mepc          # trap saved the faulting pc
        addi  t6, t6, 4         # step past the annulled store
        csrw  mepc, t6
        mret
