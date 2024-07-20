import cv2
import os
from picamera2 import Picamera2, Preview
import time
import serial

# UART configuration
ser = serial.Serial('/dev/ttyUSB0', 19200)  

cascade_path = '/home/brad/opencv/data/haarcascades/haarcascade_frontalface_default.xml'
if not os.path.exists(cascade_path):
    print(f"Error: Cascade file not found at {cascade_path}")
    exit()

face_cascade = cv2.CascadeClassifier(cascade_path)
picam2 = Picamera2()

# square format
camera_config = picam2.create_preview_configuration(main={"size": (1080, 1080)})

picam2.configure(camera_config)
picam2.start()

# frame counter
frame_counter = 0
print_interval = 4  # Print every 4 frames

def convert_and_send(value):
    # Ensure the value is within the 10-bit range
    # Convert value to 8-bit binary string
    binary_value = f'{value:08b}'  # Changed from 8b to 08b to ensure zero-padding
    # Add '1' before and '0' after
    uart_frame = '1' + binary_value + '0'
    # Reverse the binary string to send LSB first
    reversed_frame = uart_frame[::-1]
    # Convert the reversed binary string to bytes
    byte_value = int(reversed_frame, 2).to_bytes(2, byteorder='big')
    # Send the byte over UART
    ser.write(byte_value)

while True:
    frame = picam2.capture_array()

    scale_factor = 0.5  
    frame = cv2.resize(frame, (0, 0), fx=scale_factor, fy=scale_factor)
    # grayscale conversion
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

    faces = face_cascade.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=5, minSize=(30, 30))

    # create rectangle around face, find center coords
    for (x, y, w, h) in faces:
        cv2.rectangle(frame, (x, y), (x + w, y + h), (255, 255, 255), 5)
        center_x = x + w // 2
        center_y = y + h // 2

        # Scaling the coordinates to 0-100 range with 50 in the middle
        frame_width = frame.shape[1]
        frame_height = frame.shape[0]
        scaled_x = int((center_x / frame_width) * 100)
        scaled_y = int((1-(center_y / frame_height)) * 100)

        if frame_counter % print_interval == 0:
            print(f"{scaled_x:03d}.{scaled_y:03d}")
            # Convert to unsigned and send over UART
            convert_and_send(scaled_x)
            convert_and_send(scaled_y)

    frame_counter += 1

    cv2.imshow('Face Detection', frame)

    # Break the loop on 'q'
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cv2.destroyAllWindows()
ser.close()