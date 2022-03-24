# Import required packages
import cv2
import pytesseract
import redis
from minio import Minio
import os, sys
import json

r = redis.Redis(host=os.environ.get('REDIS_HOST'), port=6379, db=0)

client = Minio(
    os.environ.get('MINIO_URL'),
    access_key=os.environ.get('MINIO_ACCESS_KEY'),
    secret_key=os.environ.get('MINIO_SECRET_KEY'),
    secure=False
)

try:
    response = client.get_object(json.loads(sys.argv[1])['bucket']['name'], json.loads(sys.argv[1])['object']['key'])
    # Read data from response.
    with open('input.jpg', 'wb') as file_data:
        for data in response:
            file_data.write(data)
    file_data.close()
finally:
    response.close()
    response.release_conn()

# Mention the installed location of Tesseract-OCR in your system
pytesseract.pytesseract.tesseract_cmd = 'tesseract'

# Read image from which text needs to be extracted
img = cv2.imread("input.jpg")

# Preprocessing the image starts

# Convert the image to gray scale
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

# Performing OTSU threshold
ret, thresh1 = cv2.threshold(gray, 0, 255, cv2.THRESH_OTSU | cv2.THRESH_BINARY_INV)

# Specify structure shape and kernel size.
# Kernel size increases or decreases the area
# of the rectangle to be detected.
# A smaller value like (10, 10) will detect
# each word instead of a sentence.
rect_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (10, 10))

# Applying dilation on the threshold image
dilation = cv2.dilate(thresh1, rect_kernel, iterations = 1)

# Finding contours
contours, hierarchy = cv2.findContours(dilation, cv2.RETR_EXTERNAL,
												cv2.CHAIN_APPROX_NONE)

# Creating a copy of image
im2 = img.copy()

# A text file is created and flushed
#file = open("recognized.txt", "w+")
#file.write("")
#file.close()

# Looping through the identified contours
# Then rectangular part is cropped and passed on
# to pytesseract for extracting text from it
# Extracted text is then written into the text file
for cnt in contours:
    x, y, w, h = cv2.boundingRect(cnt)

	# Drawing a rectangle on copied image
    rect = cv2.rectangle(im2, (x, y), (x + w, y + h), (0, 255, 0), 2)

	# Cropping the text block for giving input to OCR
    cropped = im2[y:y + h, x:x + w]

	# Open the file in append mode
	#file = open("recognized.txt", "a")

	# Apply OCR on the cropped image
    text = pytesseract.image_to_string(cropped)
    lines = text.split('\n')
    for line in lines:
        if len(line.strip())>= 3:
            r.publish('tesseract', line)
