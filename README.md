Area Measurement Tool

A computer vision application that measures the area of shapes in real-time using a webcam. The system uses a red reference line for calibration and can detect multiple shapes simultaneously.

Overview

- Real-time shape detection and area calculation
- Reference-based measurement using red markers
- Interactive control panel for detection settings
- Split-screen interface with shape isolation
- Adjustable parameters for different environments

How to Use

1. Run the application
2. Place a red line of known length in view
3. Place objects to measure
4. Use controls to select and measure shapes:
   - Enter: Switch shapes
   - M: Switch reference lines
   - +/-: Adjust reference length
   - Q: Quit

Detection settings can be fine-tuned using the control panel for different lighting conditions and shape types.

Requirements
- Python 3.x
- OpenCV
- NumPy

Note
Best results achieved with:
- Good lighting
- Clear contrast between objects and background
- Camera perpendicular to measured objects
