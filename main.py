import cv2
import numpy as np

class AreaCalculator:
    def __init__(self):
        self.current_metric_index = 0
        self.current_shape_index = 0
        self.metric_lines = []
        self.shape_contours = []
        self.known_length = 10
        self.frame = None
        self.output = None

        # Settings parameters
        self.metric_settings = {
            'min_area': 100,
            'red_sensitivity': 100,
            'noise_reduction': 5
        }

        self.shape_settings = {
            'min_area': 1000,
            'threshold': 127,
            'blur': 5
        }

        # Initialize webcam
        self.cap = cv2.VideoCapture(0)
        if not self.cap.isOpened():
            raise ValueError("Could not open webcam")

        # Set webcam resolution
        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1920)
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 1080)

        # Create window and trackbars
        cv2.namedWindow('Area Calculator', cv2.WINDOW_NORMAL)
        cv2.setWindowProperty('Area Calculator', cv2.WND_PROP_FULLSCREEN,
                              cv2.WINDOW_FULLSCREEN)
        self.create_trackbars()

    def create_trackbars(self):
        cv2.createTrackbar('M-Min Area', 'Area Calculator',
                           self.metric_settings['min_area'], 1000,
                           lambda x: self.update_setting('metric', 'min_area', x))
        cv2.createTrackbar('M-Red Sensitivity', 'Area Calculator',
                           self.metric_settings['red_sensitivity'], 255,
                           lambda x: self.update_setting('metric', 'red_sensitivity', x))
        cv2.createTrackbar('M-Noise Reduction', 'Area Calculator',
                           self.metric_settings['noise_reduction'], 20,
                           lambda x: self.update_setting('metric', 'noise_reduction', x))
        cv2.createTrackbar('S-Min Area', 'Area Calculator',
                           self.shape_settings['min_area'], 5000,
                           lambda x: self.update_setting('shape', 'min_area', x))
        cv2.createTrackbar('S-Threshold', 'Area Calculator',
                           self.shape_settings['threshold'], 255,
                           lambda x: self.update_setting('shape', 'threshold', x))
        cv2.createTrackbar('S-Blur', 'Area Calculator',
                           self.shape_settings['blur'], 20,
                           lambda x: self.update_setting('shape', 'blur', x))

    def update_setting(self, category, setting, value):
        if category == 'metric':
            self.metric_settings[setting] = value
        elif category == 'shape':
            self.shape_settings[setting] = value

    def detect_red_line(self, frame):
        try:
            hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)

            sensitivity = self.metric_settings['red_sensitivity']
            lower_red1 = np.array([0, sensitivity, sensitivity])
            upper_red1 = np.array([10, 255, 255])
            lower_red2 = np.array([160, sensitivity, sensitivity])
            upper_red2 = np.array([180, 255, 255])

            mask1 = cv2.inRange(hsv, lower_red1, upper_red1)
            mask2 = cv2.inRange(hsv, lower_red2, upper_red2)
            red_mask = mask1 + mask2

            kernel_size = max(1, self.metric_settings['noise_reduction'])
            if kernel_size % 2 == 0:
                kernel_size += 1
            kernel = np.ones((kernel_size, kernel_size), np.uint8)
            red_mask = cv2.morphologyEx(red_mask, cv2.MORPH_OPEN, kernel)
            red_mask = cv2.morphologyEx(red_mask, cv2.MORPH_CLOSE, kernel)

            contours, _ = cv2.findContours(red_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
            self.metric_lines = [cnt for cnt in contours
                                 if cv2.contourArea(cnt) > self.metric_settings['min_area']]

            if self.metric_lines:
                self.current_metric_index = min(self.current_metric_index, len(self.metric_lines) - 1)
            else:
                self.current_metric_index = 0

            return red_mask
        except Exception as e:
            print(f"Error in detect_red_line: {str(e)}")
            return np.zeros_like(frame[:,:,0])

    def detect_shape(self, frame):
        try:
            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

            blur_size = max(1, self.shape_settings['blur'])
            if blur_size % 2 == 0:
                blur_size += 1
            blurred = cv2.GaussianBlur(gray, (blur_size, blur_size), 0)

            _, thresh = cv2.threshold(blurred, self.shape_settings['threshold'],
                                      255, cv2.THRESH_BINARY_INV)

            contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

            self.shape_contours = []
            for contour in contours:
                area = cv2.contourArea(contour)
                if area > self.shape_settings['min_area']:
                    peri = cv2.arcLength(contour, True)
                    approx = cv2.approxPolyDP(contour, 0.02 * peri, True)
                    if len(approx) >= 3:
                        self.shape_contours.append(contour)

            # Reset shape index if needed
            if self.shape_contours:
                self.current_shape_index = min(self.current_shape_index, len(self.shape_contours) - 1)
            else:
                self.current_shape_index = 0

        except Exception as e:
            print(f"Error in detect_shape: {str(e)}")
            self.shape_contours = []

    def get_line_length(self, contour):
        try:
            rect = cv2.minAreaRect(contour)
            return max(rect[1][0], rect[1][1])
        except:
            return 0

    def create_combined_display(self, main_frame, red_mask):
        try:
            screen_width = 1920
            screen_height = 1080
            panel_width = screen_width // 2
            panel_height = screen_height // 2

            # Resize main frame and prepare selected shape panel
            main_frame_resized = cv2.resize(main_frame, (panel_width, panel_height))
            shape_panel = np.zeros((panel_height, panel_width, 3), dtype=np.uint8)
            shape_panel.fill(50)

            # Display selected shape if available
            if self.shape_contours and len(self.shape_contours) > self.current_shape_index:
                current_shape = self.shape_contours[self.current_shape_index]
                shape_mask = np.zeros_like(self.frame)
                cv2.drawContours(shape_mask, [current_shape], -1, (255, 255, 255), -1)

                x, y, w, h = cv2.boundingRect(current_shape)
                shape_region = cv2.bitwise_and(self.frame, shape_mask)
                shape_region = shape_region[y:y+h, x:x+w]

                if shape_region.size > 0:
                    # Resize shape to fit panel while maintaining aspect ratio
                    aspect_ratio = w / h
                    if aspect_ratio > 1:
                        new_w = min(panel_width - 40, int(panel_height * aspect_ratio))
                        new_h = int(new_w / aspect_ratio)
                    else:
                        new_h = min(panel_height - 40, int(panel_width / aspect_ratio))
                        new_w = int(new_h * aspect_ratio)

                    if new_w > 0 and new_h > 0:
                        shape_region_resized = cv2.resize(shape_region, (new_w, new_h))
                        y_offset = (panel_height - new_h) // 2
                        x_offset = (panel_width - new_w) // 2
                        shape_panel[y_offset:y_offset+new_h,
                        x_offset:x_offset+new_w] = shape_region_resized

                # Add shape information
                cv2.putText(shape_panel, f"Shape {self.current_shape_index + 1}/{len(self.shape_contours)}",
                            (20, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (200, 200, 200), 2)

                if self.metric_lines:
                    current_metric = self.metric_lines[self.current_metric_index]
                    pixel_length = self.get_line_length(current_metric)
                    if pixel_length > 0:
                        pixel_to_metric_ratio = self.known_length / pixel_length
                        area = cv2.contourArea(current_shape) * (pixel_to_metric_ratio ** 2)
                        cv2.putText(shape_panel, f"Area: {area:.2f} sq units",
                                    (20, 60), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
            else:
                cv2.putText(shape_panel, "No shape selected",
                            (20, panel_height//2), cv2.FONT_HERSHEY_SIMPLEX,
                            1, (200, 200, 200), 2)

            # Create settings panels
            settings_panel1 = np.zeros((panel_height, panel_width, 3), dtype=np.uint8)
            settings_panel1.fill(50)
            settings_panel2 = np.zeros((panel_height, panel_width, 3), dtype=np.uint8)
            settings_panel2.fill(50)

            # Draw settings information
            cv2.putText(settings_panel1, "Metric Detection Settings",
                        (20, 40), cv2.FONT_HERSHEY_SIMPLEX, 1, (200, 200, 200), 2)
            y_offset = 100
            for i, (key, value) in enumerate(self.metric_settings.items()):
                text = f"{key}: {value}"
                cv2.putText(settings_panel1, text, (20, y_offset + i*50),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.8, (150, 150, 150), 2)

            cv2.putText(settings_panel2, "Shape Detection Settings",
                        (20, 40), cv2.FONT_HERSHEY_SIMPLEX, 1, (200, 200, 200), 2)
            for i, (key, value) in enumerate(self.shape_settings.items()):
                text = f"{key}: {value}"
                cv2.putText(settings_panel2, text, (20, y_offset + i*50),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.8, (150, 150, 150), 2)

            # Draw controls help
            cv2.putText(settings_panel1,
                        "Enter: Switch shape | M: Switch metric | +/-: Adjust length | Q: Quit",
                        (20, panel_height - 40), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (200, 200, 200), 2)

            # Combine panels
            top_row = np.hstack((main_frame_resized, shape_panel))
            bottom_row = np.hstack((settings_panel1, settings_panel2))
            combined = np.vstack((top_row, bottom_row))

            return combined

        except Exception as e:
            print(f"Error in create_combined_display: {str(e)}")
            return main_frame

    def calculate_areas(self):
        if not self.metric_lines:
            return

        try:
            current_metric = self.metric_lines[self.current_metric_index]
            pixel_length = self.get_line_length(current_metric)

            if pixel_length == 0:
                return

            pixel_to_metric_ratio = self.known_length / pixel_length
            self.output = self.frame.copy()

            # Draw all metric lines
            for i, metric in enumerate(self.metric_lines):
                color = (0, 0, 255) if i == self.current_metric_index else (128, 128, 128)
                cv2.drawContours(self.output, [metric], -1, color, 2)

            # Draw all shapes
            for i, contour in enumerate(self.shape_contours):
                color = (0, 255, 0) if i == self.current_shape_index else (0, 150, 0)
                cv2.drawContours(self.output, [contour], -1, color, 2)

                M = cv2.moments(contour)
                if M["m00"] != 0:
                    cX = int(M["m10"] / M["m00"])
                    cY = int(M["m01"] / M["m00"])
                    pixel_area = cv2.contourArea(contour)
                    real_area = pixel_area * (pixel_to_metric_ratio ** 2)
                    text = f"Area: {real_area:.2f}"
                    cv2.putText(self.output, text, (cX - 50, cY),
                                cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 0, 0), 2)

        except Exception as e:
            print(f"Error in calculate_areas: {str(e)}")
            self.current_metric_index = 0

    def run(self):
        try:
            while True:
                ret, self.frame = self.cap.read()
                if not ret:
                    print("Error: Could not read frame")
                    break

                self.frame = cv2.flip(self.frame, 1)
                red_mask = self.detect_red_line(self.frame)
                self.detect_shape(self.frame)

                if self.metric_lines:
                    self.calculate_areas()
                    display_frame = self.output
                else:
                    display_frame = self.frame
                    cv2.putText(display_frame, "No metric line detected",
                                (10, 30), cv2.FONT_HERSHEY_SIMPLEX,
                                0.7, (0, 0, 255), 2)

                combined_display = self.create_combined_display(display_frame, red_mask)
                cv2.imshow('Area Calculator', combined_display)

                key = cv2.waitKey(1) & 0xFF
                if key == 13:  # Enter key
                    if self.shape_contours:
                        self.current_shape_index = (self.current_shape_index + 1) % len(self.shape_contours)
                elif key == ord('m') or key == ord('M'):
                    if self.metric_lines:
                        self.current_metric_index = (self.current_metric_index + 1) % len(self.metric_lines)
                elif key == ord('+'):
                    self.known_length += 1
                elif key == ord('-'):
                    self.known_length = max(1, self.known_length - 1)
                elif key == ord('q') or key == 27:
                    break

        except Exception as e:
            print(f"Error in run: {str(e)}")
        finally:
            self.cap.release()
            cv2.destroyAllWindows()

def main():
    try:
        calculator = AreaCalculator()
        calculator.run()
    except Exception as e:
        print(f"Error: {str(e)}")

if __name__ == "__main__":
    main()