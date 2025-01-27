import cv2
import numpy as np

def detect_red_line(image):
    # Convert image to HSV color space
    hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)

    # Define range for red color
    lower_red1 = np.array([0, 100, 100])
    upper_red1 = np.array([10, 255, 255])
    lower_red2 = np.array([160, 100, 100])
    upper_red2 = np.array([180, 255, 255])

    # Create masks for red color
    mask1 = cv2.inRange(hsv, lower_red1, upper_red1)
    mask2 = cv2.inRange(hsv, lower_red2, upper_red2)
    red_mask = mask1 + mask2

    return red_mask

def detect_shape(image):
    # Convert image to grayscale
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    # Apply threshold
    _, thresh = cv2.threshold(gray, 127, 255, cv2.THRESH_BINARY)

    # Find contours
    contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    return contours

def main():
    # Read the image
    image = cv2.imread('your_image.png')
    if image is None:
        print("Error: Could not load image")
        return

    # Get red line mask
    red_mask = detect_red_line(image)

    # Get shape contours
    contours = detect_shape(image)

    # Draw contours on original image
    cv2.drawContours(image, contours, -1, (0, 255, 0), 2)

    # Show results
    cv2.imshow('Original Image with Contours', image)
    cv2.imshow('Red Line Mask', red_mask)
    cv2.waitKey(0)
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()