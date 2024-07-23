import serial
import subprocess
import logging

logging.basicConfig(filename='/home/brad/uart_listener.log', level=logging.INFO)
logging.info('UART Listener started')

ser = serial.Serial('/dev/ttyUSB0', baudrate=9600, timeout=1)

while True:
    command = ser.readline().decode('utf-8').strip()
    if command:
        logging.info(f'Received command: {command}')
        try:
            subprocess.run(command, shell=True)
        except Exception as e:
            ser.write(f"Error: {str(e)}\n".encode('utf-8'))
            logging.error(f'Error executing command: {str(e)}')
