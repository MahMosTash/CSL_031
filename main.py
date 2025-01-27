import cv2
import numpy as np

def detect_red_line(image):
    hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)

    # Red color ranges
    lower_red1 = np.array([0, 100, 100])
    upper_red1 = np.array([10, 255, 255])
    lower_red2 = np.array([160, 100, 100])
    upper_red2 = np.array([180, 255, 255])

    # Create masks
    mask1 = cv2.inRange(hsv, lower_red1, upper_red1)
    mask2 = cv2.inRange(hsv, lower_red2, upper_red2)
    red_mask = mask1 + mask2

    # Noise removal
    kernel = np.ones((5,5), np.uint8)
    red_mask = cv2.morphologyEx(red_mask, cv2.MORPH_OPEN, kernel)
    red_mask = cv2.morphologyEx(red_mask, cv2.MORPH_CLOSE, kernel)

    return red_mask

def detect_shape(image):
    # Convert to grayscale
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    # Apply blur
    blurred = cv2.GaussianBlur(gray, (5, 5), 0)

    # Threshold
    _, thresh = cv2.threshold(blurred, 127, 255, cv2.THRESH_BINARY)

    # Find contours
    contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    # Filter contours
    filtered_contours = []
    for contour in contours:
        area = cv2.contourArea(contour)
        if area > 100:  # Minimum area threshold
            filtered_contours.append(contour)

    return filtered_contours

def get_red_line_length(red_mask):
    # Find contours of the red line
    contours, _ = cv2.findContours(red_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    if not contours:
        return None

    # Get the longest contour (assumed to be the metric line)
    longest_contour = max(contours, key=cv2.contourArea)

    # Get the minimum bounding rectangle
    rect = cv2.minAreaRect(longest_contour)
    box = cv2.boxPoints(rect)
    box = np.int0(box)

    # Calculate the length of the line in pixels
    width = rect[1][0]
    height = rect[1][1]
    pixel_length = max(width, height)

    return pixel_length

def calculate_pixel_to_metric_ratio(pixel_length, known_length):
    """
    Calculate the ratio of pixels to metric units
    known_length should be in the desired unit (e.g., cm, mm, etc.)
    """
    if pixel_length is None or pixel_length == 0:
        return None
    return known_length / pixel_length

def calculate_area(contour, pixel_to_metric_ratio):
    """
    Calculate the area in real-world units
    """
    if pixel_to_metric_ratio is None:
        return None

    # Get area in pixels
    pixel_area = cv2.contourArea(contour)

    # Convert to real-world units
    real_area = pixel_area * (pixel_to_metric_ratio ** 2)

    return real_area

def main():
    # Read image
    image = cv2.imread('your_image.png')
    if image is None:
        print("Error: Could not load image")
        return

    # Make a copy for drawing
    output = image.copy()

    # Known length of the red line in your desired units (e.g., cm)
    KNOWN_LENGTH = 10  # Change this to your actual reference length

    # Detect red line
    red_mask = detect_red_line(image)
    pixel_length = get_red_line_length(red_mask)

    if pixel_length is None:
        print("Error: Could not detect reference line")
        return

    # Calculate pixel to metric ratio
    pixel_to_metric_ratio = calculate_pixel_to_metric_ratio(pixel_length, KNOWN_LENGTH)

    if pixel_to_metric_ratio is None:
        print("Error: Could not calculate pixel to metric ratio")
        return

    # Detect shapes
    shape_contours = detect_shape(image)

    if not shape_contours:
        print("Error: No shapes detected")
        return

    # Calculate and display area for each detected shape
    for i, contour in enumerate(shape_contours):
        # Calculate area
        area = calculate_area(contour, pixel_to_metric_ratio)

        if area is not None:
            # Draw contour
            cv2.drawContours(output, [contour], -1, (0, 255, 0), 2)

            # Calculate centroid for text placement
            M = cv2.moments(contour)
            if M["m00"] != 0:
                cX = int(M["m10"] / M["m00"])
                cY = int(M["m01"] / M["m00"])
            else:
                cX, cY = 0, 0

            # Draw area value on image
            text = f"Area: {area:.2f} sq units"
            cv2.putText(output, text, (cX - 50, cY),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 0, 0), 2)

    # Draw reference line information
    cv2.putText(output, f"Reference Length: {KNOWN_LENGTH} units",
                (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)

    # Display results
    cv2.imshow('Original Image', image)
    cv2.imshow('Red Mask', red_mask)
    cv2.imshow('Results', output)

    # Save the result
    cv2.imwrite('result.jpg', output)

    cv2.waitKey(0)
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()