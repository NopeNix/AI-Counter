import time
import argparse
import os
from modules.utils.image_utils import ImageProcessor
from modules.models.efficientdet_detector import EfficientDetDetector
from modules.models.ssd_detector import SSDDetector

# Default URL for SSD model
DEFAULT_SSD_MODEL_URL = "https://tfhub.dev/google/openimages_v4/ssd/mobilenet_v2/1"

# Determine the absolute path to the EfficientDet class labels JSON file
script_dir = os.path.dirname(__file__)
EFFICIENTDET_LABEL_PATH = os.path.join(script_dir, 'modules/models/efficientdet_classes.json')

def detect_img(image_url, model_url):
    start_time = time.time()

    # Using the ImageProcessor class to handle image downloading and resizing
    image = ImageProcessor.download_and_resize_image(image_url, 1920, 1080)
    if image is None:
        print("Failed to process the image.")
        return

    # Loading the image tensor using the ImageProcessor class
    image_tensor = ImageProcessor.load_img_from_memory(image, model_url)

    # Determine the appropriate detector based on the model URL
    if "efficientdet" in model_url:
        detector = EfficientDetDetector(model_url, EFFICIENTDET_LABEL_PATH)
        result = detector.format_detections(detector.run(image_tensor))
    else:
        detector = SSDDetector(model_url)
        result = detector.run(image_tensor)

    # Running the detector and getting results
    end_time = time.time()
    print("Inference time:", end_time - start_time)
    print(result)

# Argument parser setup
parser = argparse.ArgumentParser(description="Run a TensorFlow detector model on an image from a URL.")
parser.add_argument("--url", required=True, help="URL of the image to process.")
parser.add_argument("--model", default=DEFAULT_SSD_MODEL_URL, help="URL of the TensorFlow Hub model to use.")

args = parser.parse_args()

# Starting detection
print(f"Starting to detect image: {args.url}")

detect_img(args.url, args.model)