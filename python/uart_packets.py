#!/usr/bin/env python3
import serial
import threading
import sys

OPCODE_ECHO = 0xEC
OPCODE_ADD32 = 0xA0
OPCODE_MUL32 = 0xA1
OPCODE_DIV32 = 0xA2

def parse_rx_packet(packet):
    opcode = packet[0]
    length = packet[1] | (packet[2] << 8)
    payload = packet[4:]
    print(f"Received Packet - Opcode: {opcode}, Length: {length}, Payload: {payload}")

def read_thread(ser):
    while True:
        if ser.in_waiting:
            data = ser.read(ser.in_waiting)
            if data:
                print("RX bytes:", list(data))
                print("RX hex  :", ' '.join(f'{byte:02X}' for byte in data))

                try:
                    ascii_str = data.decode('ascii')
                    print("RX ASCII :", ascii_str)
                except UnicodeDecodeError:
                    print("RX ASCII :", "<Non-ASCII Data>")

                if len(data) == 8:
                    remainder = int.from_bytes(data[:4], 'little', signed=True)
                    quotient = int.from_bytes(data[4:], 'little', signed=True)
                    print(f"RX Division - Quotient: {quotient}, Remainder: {remainder}")
                elif len(data) == 4:
                    result = int.from_bytes(data, 'little', signed=True)
                    print(f"RX Int   : {result}")
                elif len(data) > 4:
                    try:
                        ascii_str = data.decode('ascii')
                        print("RX Multi ASCII :", ascii_str)
                    except UnicodeDecodeError:
                        print("RX Multi ASCII :", "<Non-ASCII Data>")
        else:
            pass


def build_packet(opcode, payload):
    reserved = 0x00
    data_length = len(payload)
    length_lsb = data_length & 0xFF
    length_msb = (data_length >> 8) & 0xFF

    packet = bytearray()
    packet.append(opcode)
    packet.append(reserved)
    packet.append(length_lsb)
    packet.append(length_msb)
    packet.extend(payload)
    return packet

def echo(ser, message):
    payload = message.encode('ascii')
    packet = build_packet(OPCODE_ECHO, payload)
    ser.write(packet)
    print("TX echo packet:", list(packet))

def add32(ser, operands):
    payload = bytearray()
    for val in operands:
        payload.extend(val.to_bytes(4, 'little', signed=True))
    packet = build_packet(OPCODE_ADD32, payload)
    ser.write(packet)
    print("TX add32 packet:", list(packet))

def mul32(ser, operands):
    payload = bytearray()
    for val in operands:
        payload.extend(val.to_bytes(4, 'little', signed=True))
    packet = build_packet(OPCODE_MUL32, payload)
    ser.write(packet)
    print("TX mul32 packet:", list(packet))

def div32(ser, numerator, denominator):
    payload = bytearray()
    payload.extend(numerator.to_bytes(4, 'little', signed=True))
    payload.extend(denominator.to_bytes(4, 'little', signed=True))
    packet = build_packet(OPCODE_DIV32, payload)
    ser.write(packet)
    print("TX div32 packet:", list(packet))

def main():
    if len(sys.argv) > 1:
        port = sys.argv[1]
    else:
        port = "/dev/ttyUSB1"

    ser = serial.Serial(port=port, baudrate=115200, timeout=0)
    t = threading.Thread(target=read_thread, args=(ser,), daemon=True)
    t.start()

    print(f"Opened {port} at 115200 baud.")
    print("Commands: 'echo <text>', 'add <vals>', 'mul <vals>', 'div <n> <d>', or 'quit'")

    try:
        while True:
            user_in = input("> ")
            if not user_in.strip():
                continue
            tokens = user_in.split()
            cmd = tokens[0].lower()

            if cmd == "quit":
                break
            elif cmd == "echo":
                message = " ".join(tokens[1:])
                echo(ser, message)
            elif cmd == "add":
                if len(tokens) < 3:
                    print("Usage: add <val1> <val2> ...")
                    continue
                try:
                    ops = [int(x) for x in tokens[1:]]
                except ValueError:
                    print("Operands must be integers.")
                    continue
                add32(ser, ops)
            elif cmd == "mul":
                if len(tokens) < 3:
                    print("Usage: mul <val1> <val2> ...")
                    continue
                try:
                    ops = [int(x) for x in tokens[1:]]
                except ValueError:
                    print("Operands must be integers.")
                    continue
                mul32(ser, ops)
            elif cmd == "div":
                if len(tokens) < 3:
                    print("Usage: div <numerator> <denominator>")
                    continue
                try:
                    numerator = int(tokens[1])
                    denominator = int(tokens[2])
                except ValueError:
                    print("Numerator and denominator must be integers.")
                    continue
                div32(ser, numerator, denominator)
            else:
                print("Unknown command. Try: echo, add, mul, div, or quit.")
    finally:
        ser.close()
        print("Port closed.")

if __name__ == "__main__":
    main()
