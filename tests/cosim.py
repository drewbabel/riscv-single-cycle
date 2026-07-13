#!/usr/bin/env python3
# Lockstep co-sim of the core against Spike
# python3 tests/cosim.py <prog>

import os
import re
import subprocess
import sys

BASE = 0x8000_0000  # Spike DRAM base
DEPTH = 64
MASK32 = 0xFFFF_FFFF
ABS_PC_OPS = {0x17, 0x6F, 0x67}  # auipc jal jalr

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BUILD = os.path.join(ROOT, "build")
RTL = [os.path.join(ROOT, "rtl", "alu_pkg.sv")] + [  # package first
    os.path.join(ROOT, "rtl", f)
    for f in sorted(os.listdir(os.path.join(ROOT, "rtl")))
    if f.endswith(".sv") and f != "alu_pkg.sv"
]

RVGCC = "riscv64-elf-gcc"
GCC_COMMON = ["-march=rv32i", "-mabi=ilp32", "-nostdlib", "-nostartfiles"]
SIM = os.path.join(BUILD, "cosim_sim")


def sh(cmd):
    subprocess.run(cmd, check=True, cwd=ROOT)


# compile the monitor once
def compile_monitor():
    os.makedirs(BUILD, exist_ok=True)
    sh(["iverilog", "-g2012", "-s", "cosim", "-o", SIM, *RTL, os.path.join("tb", "cosim.sv")])


# dut hex plus spike elf
def build_images(src, hexout, spike_elf):
    dut_elf = os.path.join(BUILD, "dut.elf")
    sh([RVGCC, *GCC_COMMON, "-T", "tests/link.ld", "-o", dut_elf, src])
    sh(["riscv64-elf-objcopy", "-O", "verilog", "--verilog-data-width=4", dut_elf, hexout])
    sh([RVGCC, *GCC_COMMON, "-T", "tests/link_spike.ld", "-o", spike_elf, src])


# dut commit trace
def run_dut(dut_hex):
    out = subprocess.run(["vvp", SIM, f"+hex={dut_hex}", "+n=4000"],
                         cwd=ROOT, capture_output=True, text=True).stdout
    trace = []
    for line in out.splitlines():
        m = re.match(r"COMMIT ([0-9a-f]+) (\d+) ([0-9a-f]+) (\d+) ([0-9a-f]+) ([0-9a-f]+)", line)
        if not m:
            continue
        pc, rd, val, mw, maddr, mval = m.groups()
        rd_i = int(rd)
        val_i = (int(val, 16) & MASK32) if rd_i else 0  # x0 carries no value
        st_word = (int(maddr, 16) >> 2) & (DEPTH - 1) if mw == "1" else None
        st_val = int(mval, 16) & MASK32 if mw == "1" else None
        trace.append((int(pc, 16), rd_i, val_i, st_word, st_val))
    return trace


SPIKE_RE = re.compile(r"core\s+\d+:\s+\d+\s+0x([0-9a-f]+)\s+\(0x([0-9a-f]+)\)(.*)")  # commit line


# golden spike trace
def run_spike(spike_elf, n):
    maxlines = 4 * n + 200  # head ends the park-loop
    cmd = f"spike --isa=rv32i --pc={hex(BASE)} -l --log-commits {spike_elf} 2>&1 | head -n {maxlines}"
    out = subprocess.run(cmd, shell=True, cwd=ROOT, capture_output=True, text=True).stdout
    trace = []
    for line in out.splitlines():
        m = SPIKE_RE.match(line)
        if not m:
            continue
        pc_raw, instr_hex, tail = m.groups()
        opcode = int(instr_hex, 16) & 0x7F
        rd, val = 0, 0
        rm = re.search(r"(?:^|\s)x(\d+)\s+0x([0-9a-f]+)", tail)  # register write
        if rm:
            rd = int(rm.group(1))
            val = int(rm.group(2), 16) & MASK32
            if opcode in ABS_PC_OPS and rd != 0:
                val = (val - BASE) & MASK32  # to dut space
        st_word, st_val = None, None
        sm = re.search(r"mem\s+0x([0-9a-f]+)\s+0x([0-9a-f]+)", tail)  # store
        if sm:
            st_word = (int(sm.group(1), 16) >> 2) & (DEPTH - 1)
            st_val = int(sm.group(2), 16) & MASK32
        pc = (int(pc_raw, 16) - BASE) & MASK32  # to dut space
        trace.append((pc, rd if rd != 0 else 0, val, st_word, st_val))
        if len(trace) >= n:
            break
    return trace


def fmt(rec):
    pc, rd, val, sw, sv = rec
    parts = [f"pc={pc:08x}", f"x{rd}={val:08x}" if rd else "x0"]
    if sw is not None:
        parts.append(f"mem[{sw}]={sv:08x}")
    return "  ".join(parts)


# first mismatch wins
def compare(dut, spike):
    n = min(len(dut), len(spike))
    for i in range(n):
        if dut[i] != spike[i]:
            return False, f"instr {i}\n  DUT   {fmt(dut[i])}\n  Spike {fmt(spike[i])}"
    if len(dut) != len(spike):
        return False, f"length DUT {len(dut)} Spike {len(spike)}"
    return True, n


def main():
    if len(sys.argv) != 2:
        sys.exit("usage: python3 tests/cosim.py <prog>")
    prog = sys.argv[1]
    compile_monitor()
    src = os.path.join("tests", f"{prog}.s")
    dut_hex = os.path.join("tests", f"{prog}.hex")
    spike_elf = os.path.join(BUILD, f"{prog}_spike.elf")
    build_images(src, dut_hex, spike_elf)
    dut = run_dut(dut_hex)
    spike = run_spike(spike_elf, len(dut))
    ok, detail = compare(dut, spike)
    if not ok:
        print(f"DIVERGENCE {detail}")
        sys.exit(1)
    print(f"LOCKSTEP PASS: {detail} instructions match Spike ({prog})")


if __name__ == "__main__":
    main()
