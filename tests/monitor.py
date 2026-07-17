#!/usr/bin/env python3
# Print serial output
# python3 tests/monitor.py <serial-port>

import sys
import serial


def main():
    port = sys.argv[1]
    ser = serial.Serial(port, 28800, timeout=None)
    while True:
        data = ser.read(1)
        if data:
            sys.stdout.write(data.decode("latin-1"))
            sys.stdout.flush()


if __name__ == "__main__":
    main()
