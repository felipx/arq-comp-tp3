import serial
import sys
import time


def serial_init(portUSB: str, baudRate: int, parity: str, stopBits: int, byteSize: int) -> serial.Serial:
    """
    Initializes and configures the serial port.

    Args:
        portUSB (str): The USB port number.
        baudRate (int): The baud rate for the serial communication.
        parity (str): The parity setting for the serial communication.
        stopBits (int): The number of stop bits for the serial communication.
        byteSize (int): The number of data bits in each byte.

    Returns:
        serial.Serial: The configured serial port object.
    """
    ser = serial.Serial(port='/dev/ttyUSB{}'.format(int(portUSB)), baudrate = baudRate, parity=parity, stopbits = stopBits, bytesize=byteSize)
    ser.isOpen()
    ser.timeout = None
    ser.flushInput()
    ser.flushOutput()
    return ser


def calculate_checksum(data: bytes) -> int:
    """
    Calculates the checksum for a block of data.

    Args:
        data (bytes): The data block to calculate the checksum for.

    Returns:
        int: The calculated checksum.
    """
    return sum(data) & 0xFF


def send_file(serial_port: serial.Serial, file_path: str):
    """
    Sends a binary file using the XMODEM protocol.

    The file is sent in 128-byte chunks. If the last chunk is less than 128 bytes,
    it is padded with 0x1A to make it 128 bytes.

    Args:
        serial_port (serial.Serial): The serial port object.
        file_path (str): The path to the binary file to be sent.

    Raises:
        Exception: If there is an issue with file transfer.
    """
    try:
        with open(file_path, 'rb') as f:
            block_number = 1

            while True:
                # Read the next 128-byte chunk from the file
                data = f.read(128)
                if not data:
                    break
                
                # If the data is less than 128 bytes, pad with 0x1A
                if len(data) < 128:
                    data = data.ljust(128, b'\x1A')
                
                # Construct the packet
                packet = bytearray()
                packet.append(0x01)  # SOH
                packet.append(block_number & 0xFF)
                packet.append((~block_number) & 0xFF)
                packet.extend(data)
                checksum = calculate_checksum(data)
                packet.append(checksum)

                print(f"Sending packet {block_number}: {packet.hex()}")

                # Send the packet over the serial port
                serial_port.write(packet)
                time.sleep(1)
                response = serial_port.read(1)

                print("response 1: " + str(response))

                if response != b'\x05':  # ACK
                    print(f"Error: Did not receive ACK for block {block_number}")
                    return

                block_number = (block_number + 1) % 256

            print(f"sending: 0x04")
            serial_port.write(b'\x04')  # EOT
            time.sleep(1)
            response = serial_port.read(1)
            print("response 2: " + str(response))
            if response != b'\x05':  # ACK
                print("Error: Did not receive ACK for EOT")
            else:
                print("File transfer completed successfully")

    except Exception as e:
        print(f"Error: {e}")
    finally:
        serial_port.close()
        print(f"Closed {serial_port}")


def main():
    """
    Main function to execute the file transfer script.

    Reads command-line arguments for serial port configuration and file path,
    then initializes the serial port and sends the file using XMODEM protocol.
    """
    if len(sys.argv) != 4:
        print("Usage: python send_xmodem.py <serial_port> <baudrate> <file_path>")
        sys.exit(1)

    portUSB = sys.argv[1]
    baudrate = int(sys.argv[2])
    parity = serial.PARITY_NONE
    stopbits = serial.STOPBITS_ONE
    bytesize = serial.EIGHTBITS
    
    serial_port = serial_init(portUSB, baudrate, parity, stopbits, bytesize)

    #serial_port = sys.argv[1]
    file_path = sys.argv[3]
    send_file(serial_port, file_path)


if __name__ == "__main__":
    main()