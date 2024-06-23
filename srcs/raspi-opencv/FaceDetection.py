import cv2
import os
from picamera2 import Picamera2, Preview
# KEY ACKNOWLEDGEMENT: USED CHATGPT TO GET STARTED WITH OPENCV
# Define the path to the Haar cascade file
cascade_path = '/home/brad/opencv/data/haarcascades/haarcascade_frontalface_default.xml'

# Check if the Haar cascade file exists
if not os.path.exists(cascade_path):
    print(f"Error: Cascade file not found at {cascade_path}")
    exit()

# Load the Haar cascade
face_cascade = cv2.CascadeClassifier(cascade_path)

# Initialize the Pi camera
picam2 = Picamera2()

# Set the camera resolution to a square format
camera_config = picam2.create_preview_configuration(main={"size": (1080, 1080)})

picam2.configure(camera_config)
picam2.start()

while True:
    # Capture frame-by-frame
    frame = picam2.capture_array()

    # Optionally, resize the frame to make it less zoomed in (adjust scale factor as needed)
    scale_factor = 0.5  # Adjust this factor as needed
    frame = cv2.resize(frame, (0, 0), fx=scale_factor, fy=scale_factor)

    # Convert frame to grayscale (Haar cascades work better on grayscale images)
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

    # Detect faces in the frame
    faces = face_cascade.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=5, minSize=(30, 30))

    # Draw rectangle around the faces and print the center coordinates
    for (x, y, w, h) in faces:
        cv2.rectangle(frame, (x, y), (x + w, y + h), (255, 255, 255), 5)
        center_x = x + w // 2
        center_y = y + h // 2
        formatted_x = f"{center_x:03d}"  # Format as three digits
        formatted_y = f"{center_y:03d}"  # Format as three digits
        print(f"{formatted_x}.{formatted_y}")

    # Display the resulting frame
    cv2.imshow('Face Detection', frame)

    # Break the loop on 'q' key press
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

# When everything is done, release the capture and destroy all windows
cv2.destroyAllWindows()