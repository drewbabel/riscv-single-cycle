#!/usr/bin/env python3
# Stream a hex image to the serial bootloader
# python3 tests/send_prog.py <serial-port> <hexfile>

import sys
import serial


def load_words(path):
    words = []
    for line in open(path):
        line = line.strip()
        if not line or line.startswith("@"):
            continue
        words += [int(tok, 16) for tok in line.split()]
    return words


def main():
    port, hexfile = sys.argv[1], sys.argv[2]
    words = load_words(hexfile)
    if not 1 <= len(words) <= 64:
        sys.exit(f"word count {len(words)} out of range 1..64")
    ser = serial.Serial(port, 115200, timeout=1)
    ser.write(bytes([len(words)]))  # count byte
    for w in words:
        ser.write(w.to_bytes(4, "little"))  # LSB-first
    ser.flush()
    ser.close()
    print(f"sent {len(words)} words to {port}")


if __name__ == "__main__":
    main()
