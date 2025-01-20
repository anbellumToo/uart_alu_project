#!/usr/bin/env python3
import serial
import threading
import sys

def read_thread(ser):
    while True:
        line = ser.readline()
        if line:
            print("RX:", line)

def main():
    if len(sys.argv) > 1:
        port = sys.argv[1]
    else:
        port = "/dev/ttyUSB3"

    ser = serial.Serial(port=port, baudrate=115200, timeout=0)
    t = threading.Thread(target=read_thread, args=(ser,), daemon=True)
    t.start()

    print(f"Opened {port} at 115200 baud.")
    print("Type something and press Enter to send it. Type 'quit' to exit.\n")

    while True:
        user_in = input("> ")
        if user_in.lower() == "quit":
            break
        ser.write(user_in.encode('ascii') + b'\n')

    ser.close()
    print("Port closed.")

if __name__ == "__main__":
    main()
