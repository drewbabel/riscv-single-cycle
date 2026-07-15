        .section .text
        .globl _start
_start:
        la    t0, handler      # trap vector -> handler
        csrw  mtvec, t0
        lui   t0, 0x02004      # t0 = 0x02004000 (mtimecmp)
        addi  t1, x0, 30       # mtimecmp low = 30
        sw    t1, 0(t0)
        sw    x0, 4(t0)        # mtimecmp high = 0
        addi  t0, x0, 0x80     # MTIE (bit 7)
        csrs  mie, t0
        csrsi mstatus, 0x8     # MIE (bit 3)
spin:   beq   x0, x0, spin     # wait for the timer interrupt
handler:
        addi  x28, x0, 42      # marker: handler ran
hloop:  beq   x0, x0, hloop    # park
