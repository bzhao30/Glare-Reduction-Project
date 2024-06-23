import serial
import subprocess

ser = serial.Serial('/dev/serial0', baudrate=9600, timeout=1)

while True:
    command = ser.readline().decode('utf-8').strip()
    if command:
        try:
            subprocess.run(command, shell=True)
        except Exception as e:
            ser.write(f"Error: {str(e)}\n".encode('utf-8'))
