        .section .text
        .globl _start
_start:
        lui   x3, 0x80008       # data base 0x80008000, clear of code in Spike
        addi  x1, x0, 15
        addi  x2, x0, 4
        add   x4, x1, x2        # 19
        sub   x5, x1, x2        # 11
        and   x6, x1, x2        # 4
        or    x7, x1, x2        # 15
        xor   x8, x1, x2        # 11
        sll   x9, x1, x2        # 240
        srl   x10, x1, x2       # 0
        slt   x11, x2, x1       # 1
        sltu  x12, x1, x2       # 0
        sw    x4, 0(x3)         # mem[0] = 19
        sw    x5, 4(x3)         # mem[1] = 11
        lw    x13, 0(x3)        # 19
        lw    x14, 4(x3)        # 11
        beq   x13, x4, l1       # taken
        addi  x20, x0, 99       # skipped
l1:     bne   x1, x2, l2        # taken
        addi  x21, x0, 88       # skipped
l2:     blt   x2, x1, l3        # taken
        addi  x22, x0, 77       # skipped
l3:     jal   x16, l4           # x16 = link, jump
        addi  x23, x0, 66       # skipped
l4:     auipc x18, 0            # x18 = address of this instr
        jalr  x17, x18, 16      # x17 = link, jump to l4+16 (done)
        addi  x24, x0, 55       # skipped
        addi  x25, x0, 44       # skipped
done:   beq   x0, x0, done
