import time
import argparse
import os
import json
import base64
from io import BytesIO

from modules.utils.image_utils import ImageProcessor
from modules.models.efficientdet_detector import EfficientDetDetector
from modules.models.ssd_detector import SSDDetector

# Default URL for SSD model
DEFAULT_SSD_MODEL_URL = "https://tfhub.dev/google/openimages_v4/ssd/mobilenet_v2/1"

# Determine the absolute path to the EfficientDet class labels JSON file
script_dir = os.path.dirname(__file__)
EFFICIENTDET_LABEL_PATH = os.path.join(script_dir, 'modules/models/efficientdet_classes.json')

def parse_filter_list(filter_str):
    if filter_str:
        return [label.strip() for label in filter_str.split(',')]
    return []

def detect_img(image_url, model_url, include_picture_with_boundingboxes, filter_classes, min_confidence):
    start_time = time.time()

    # Using the ImageProcessor class to handle image downloading and resizing
    image = ImageProcessor.download_and_resize_image(image_url, 1920, 1080)
    if image is None:
        print("Failed to process the image.")
        return

    # Save the resized image to a path
    resized_image_path = 'resized_image.jpg'
    image.save(resized_image_path)

    # Loading the image tensor using the ImageProcessor class
    image_tensor = ImageProcessor.load_img_from_memory(image, model_url)

    # Determine the appropriate detector based on the model URL
    if "efficientdet" in model_url:
        detector = EfficientDetDetector(model_url, EFFICIENTDET_LABEL_PATH)
        result_json = detector.format_detections(detector.run(image_tensor))
    else:
        detector = SSDDetector(model_url)
        result_json = detector.run(image_tensor)

    # Parse the result JSON string into a dictionary
    result = json.loads(result_json)

    # Print the result for debugging
    print("Detection Results:")
    print(json.dumps(result, indent=2))

    # Filter results based on class and confidence
    if filter_classes:
        result['detections'] = [
            det for det in result['detections']
            if det['class_label'] in filter_classes and det['score'] >= min_confidence
        ]

    # If bounding box image inclusion is requested
    if include_picture_with_boundingboxes:
        # Check the structure of detections and extract bounding boxes and labels
        bounding_boxes = []
        labels = []
        for det in result['detections']:
            if 'box' in det:
                box = det['box']
                bounding_boxes.append((box[0], box[1], box[2], box[3]))
                labels.append(det['class_label'])

        # Debug: Print extracted bounding boxes and labels
        print("Extracted Bounding Boxes:")
        print(bounding_boxes)
        print("Extracted Labels:")
        print(labels)

        # Draw the bounding boxes on the image with labels
        image_with_boxes = ImageProcessor.draw_bounding_boxes(resized_image_path, bounding_boxes, labels=labels, normalized=True)

        # Encode the image with bounding boxes for base64
        buffered = BytesIO()
        image_with_boxes.save(buffered, format="JPEG")
        img_str = base64.b64encode(buffered.getvalue()).decode("utf-8")
        result["image-base64-encoded"] = img_str

    # Running the detector and getting results
    end_time = time.time()
    print("Inference time:", end_time - start_time)
    print(json.dumps(result, indent=2))

# Argument parser setup
parser = argparse.ArgumentParser(description="Run a TensorFlow detector model on an image from a URL.")
parser.add_argument("--url", required=True, help="URL of the image to process.")
parser.add_argument("--model", default=DEFAULT_SSD_MODEL_URL, help="URL of the TensorFlow Hub model to use.")
parser.add_argument("--include-picture-with-boundingboxes", action='store_true', help="Include image with bounding boxes in the output.")
parser.add_argument("--filter", type=parse_filter_list, help="Filter detections by class labels, separated by commas.")
parser.add_argument("--min-confidence", type=float, default=0.0, help="Minimum confidence threshold for detections.")


args = parser.parse_args()

# Starting detection
print(f"Starting to detect image: {args.url}")

detect_img(args.url, args.model, args.include_picture_with_boundingboxes, args.filter, args.min_confidence)