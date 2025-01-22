#!/usr/bin/env python3
import serial
import threading
import sys
import time

OPCODE_ECHO = 0xEC
OPCODE_ADD32 = 0xA0
OPCODE_MUL32 = 0xA1
OPCODE_DIV32 = 0xA2

def parse_rx_packet(packet):
    opcode = packet[0]
    length = packet[1] | (packet[2] << 8)
    payload = packet[4:]
    print(f"Received Packet - Opcode: {opcode}, Length: {length}, Payload: {payload}")

    if opcode == OPCODE_ADD32:
        result = int.from_bytes(payload[:length], 'little', signed=True)
        print(f"Addition Result: {result}")
    elif opcode == OPCODE_MUL32:
        result = int.from_bytes(payload[:4], 'little', signed=True)
        print(f"Multiplication Result: {result}")

def read_thread(ser):
    buffer = bytearray()
    while True:
        data = ser.read(ser.in_waiting or 1)
        if data:
            buffer.extend(data)
            print(f"RX (raw bytes): {list(data)}")  # Print raw RX data continuously
            print(f"RX raw data buffer: {list(buffer)}")  # Print the full buffer

            while len(buffer) >= 4:
                length_lsb = buffer[1]
                length_msb = buffer[2]
                total_length = 4 + ((length_msb << 8) | length_lsb)

                if len(buffer) >= total_length + 4:
                    packet = buffer[:total_length + 4]
                    buffer = buffer[total_length + 4:]
                    print(f"Debug: Parsed Packet: {list(packet)}")
                    parse_rx_packet(packet)
                else:
                    break

def build_packet(opcode, payload):
    reserved = 0x00
    data_length = len(payload)  # Length of the data payload
    length_lsb = data_length & 0xFF
    length_msb = (data_length >> 8) & 0xFF

    packet = bytearray()
    packet.append(opcode)       # Opcode
    packet.append(reserved)     # Reserved
    packet.append(length_lsb)   # Length (LSB)
    packet.append(length_msb)   # Length (MSB)
    packet.extend(payload)      # Data payload
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
        port = "/dev/ttyUSB2"

    ser = serial.Serial(port=port, baudrate=115200, timeout=1)

    t = threading.Thread(target=read_thread, args=(ser,), daemon=True)
    t.start()

    print(f"Opened {port} at 115200 baud.")
    print("Commands: 'echo <text>', 'add <vals>', 'mul <vals>', 'div <n> <d>', or 'quit'")

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
            ops = [int(x) for x in tokens[1:]]
            add32(ser, ops)
        elif cmd == "mul":
            ops = [int(x) for x in tokens[1:]]
            mul32(ser, ops)
        elif cmd == "div":
            if len(tokens) < 3:
                print("Usage: div <numerator> <denominator>")
                continue
            numerator = int(tokens[1])
            denominator = int(tokens[2])
            div32(ser, numerator, denominator)
        else:
            print("Unknown command. Try: echo, add, mul, div, or quit.")

    ser.close()
    print("Port closed.")

if __name__ == "__main__":
    main()
