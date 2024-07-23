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
print_interval = 3

def convert_and_send(value_x, value_y):

    byte_x = value_x.to_bytes(1, byteorder='big', signed=False)
    byte_y = value_y.to_bytes(1, byteorder='big', signed=False)
    
    # Send each byte over UART
    ser.write(byte_x)
    ser.write(byte_y)

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
            # Convert to unsigned 8-bit and send over UART
            convert_and_send(scaled_x, scaled_y)

    frame_counter += 1

    cv2.imshow('Face Detection', frame)

    # Break the loop on 'q'
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cv2.destroyAllWindows()
ser.close()
