import cv2
import numpy as np

class AreaCalculator:
    def __init__(self):
        self.current_metric_index = 0
        self.metric_lines = []
        self.shape_contours = []
        self.known_length = 10  # Default known length
        self.image = None
        self.output = None

    def detect_red_line(self, image):
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

        # Find contours of red lines
        contours, _ = cv2.findContours(red_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        # Filter and store red line contours
        self.metric_lines = [cnt for cnt in contours if cv2.contourArea(cnt) > 100]

        return red_mask

    def detect_shape(self, image):
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        blurred = cv2.GaussianBlur(gray, (5, 5), 0)
        thresh = cv2.adaptiveThreshold(blurred, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                                       cv2.THRESH_BINARY_INV, 11, 2)

        kernel = np.ones((3,3), np.uint8)
        thresh = cv2.dilate(thresh, kernel, iterations=1)
        thresh = cv2.erode(thresh, kernel, iterations=1)

        contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        self.shape_contours = []
        for contour in contours:
            area = cv2.contourArea(contour)
            if area > 1000:
                peri = cv2.arcLength(contour, True)
                approx = cv2.approxPolyDP(contour, 0.02 * peri, True)
                if len(approx) >= 3:
                    self.shape_contours.append(contour)

    def get_line_length(self, contour):
        rect = cv2.minAreaRect(contour)
        width = rect[1][0]
        height = rect[1][1]
        return max(width, height)

    def calculate_areas(self):
        if not self.metric_lines:
            return

        # Get current metric line
        current_metric = self.metric_lines[self.current_metric_index]
        pixel_length = self.get_line_length(current_metric)

        if pixel_length == 0:
            return

        # Calculate pixel to metric ratio
        pixel_to_metric_ratio = self.known_length / pixel_length

        # Create clean output image
        self.output = self.image.copy()

        # Draw current metric line
        cv2.drawContours(self.output, [current_metric], -1, (0, 0, 255), 2)

        # Calculate and display areas
        for contour in self.shape_contours:
            pixel_area = cv2.contourArea(contour)
            real_area = pixel_area * (pixel_to_metric_ratio ** 2)

            # Draw contour
            cv2.drawContours(self.output, [contour], -1, (0, 255, 0), 2)

            # Calculate centroid
            M = cv2.moments(contour)
            if M["m00"] != 0:
                cX = int(M["m10"] / M["m00"])
                cY = int(M["m01"] / M["m00"])
            else:
                cX, cY = 0, 0

            # Draw area value
            text = f"Area: {real_area:.2f} sq units"
            cv2.putText(self.output, text, (cX - 50, cY),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 0, 0), 2)

        # Draw metric information
        cv2.putText(self.output, f"Current Metric: {self.current_metric_index + 1}/{len(self.metric_lines)}",
                    (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)
        cv2.putText(self.output, f"Reference Length: {self.known_length} units",
                    (10, 60), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)

    def run(self, image_path):
        self.image = cv2.imread(image_path)
        if self.image is None:
            print("Error: Could not load image")
            return

        # Initial detection
        red_mask = self.detect_red_line(self.image)
        self.detect_shape(self.image)

        if not self.metric_lines:
            print("Error: No red lines detected")
            return

        while True:
            # Calculate and display areas
            self.calculate_areas()

            # Display results
            cv2.imshow('Results', self.output)
            cv2.imshow('Red Mask', red_mask)

            # Handle keyboard input
            key = cv2.waitKey(1) & 0xFF

            if key == ord('m') or key == ord('M'):
                # Switch to next metric line
                self.current_metric_index = (self.current_metric_index + 1) % len(self.metric_lines)
            elif key == ord('q') or key == 27:  # 'q' or ESC
                break

        cv2.destroyAllWindows()

def main():
    calculator = AreaCalculator()
    calculator.run('your_image.png')


if __name__ == "__main__":
    main()