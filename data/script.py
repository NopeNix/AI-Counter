import time
import json
import argparse
import numpy as np
import tensorflow as tf
import tensorflow_hub as hub
import kagglehub
from urllib.request import urlopen
from io import BytesIO
from PIL import Image, ImageOps

# Print TensorFlow version and check available GPU devices.
print(tf.__version__)
print(f"The following GPU devices are available: {tf.test.gpu_device_name()}")

def load_class_labels(json_filepath):
    with open(json_filepath, 'r') as file:
        class_labels = json.load(file)
    # Convert keys from string to integer
    class_labels = {int(k): v for k, v in class_labels.items()}
    return class_labels



def load_model(model_url):
    if "tensorflow/efficientdet" in model_url:
        # This suggests a path intended for Kaggle Hub or another source, not TensorFlow Hub
        # Adjust the path as needed if kagglehub.model_download returns a path
        model_path = kagglehub.model_download(model_url)  # This function needs to be correctly defined or imported
        return tf.saved_model.load(model_path)
    else:
        # Load from TensorFlow Hub
        return hub.load(model_url).signatures['default']

def is_efficientdet_model(model_url):
    return "efficientdet" in model_url

def download_and_resize_image(url, max_width=1920, max_height=1080, display=False):
    response = urlopen(url)
    image_data = BytesIO(response.read())
    pil_image = Image.open(image_data)
    original_width, original_height = pil_image.size
    
    if original_width > max_width or original_height > max_height:
        ratio = min(max_width / original_width, max_height / original_height)
        new_size = (int(original_width * ratio), int(original_height * ratio))
        pil_image = pil_image.resize(new_size, Image.LANCZOS)
    
    pil_image_rgb = pil_image.convert("RGB")
    if display:
        pil_image_rgb.show()
    
    output = BytesIO()
    pil_image_rgb.save(output, format="JPEG", quality=90)
    output.seek(0)
    return output

def load_img_from_memory(image_data, model_url):
    # Read the image data from a BytesIO object
    image_bytes = image_data.getvalue()
    img = tf.io.decode_image(image_bytes, channels=3, expand_animations=False)

    # Check if the model is EfficientDet and adjust the tensor accordingly
    if is_efficientdet_model(model_url):
        # EfficientDet expects uint8
        img = tf.cast(img, tf.uint8)
    else:
        # Default model expects float32 with normalized values
        img = tf.image.convert_image_dtype(img, tf.float32)

    return img


def run_detector(detector, image_data, model_url, class_labels):
    img = load_img_from_memory(image_data, model_url)
    converted_img = tf.expand_dims(img, axis=0)
    result = detector(converted_img)

    if 'detection_class_entities' in result:
        # Convert tensor to numpy array and decode bytes to string
        detection_classes = [x.decode("utf-8") for x in result['detection_class_entities'].numpy()]
        detection_boxes = result['detection_boxes'].numpy()
        detection_scores = result['detection_scores'].numpy()
        num_detections = result['detection_scores'].shape[0]
    elif 'detection_classes' in result:
        # EfficientDet model or other models that output class indices
        detection_classes = result['detection_classes'][0].numpy() if result['detection_classes'].ndim == 2 else result['detection_classes'].numpy()
        detection_boxes = result['detection_boxes'][0].numpy() if result['detection_boxes'].ndim == 3 else result['detection_boxes'].numpy()
        detection_scores = result['detection_scores'][0].numpy() if result['detection_scores'].ndim == 2 else result['detection_scores'].numpy()
        num_detections = int(result['num_detections'].numpy())

    detections = []
    for i in range(num_detections):
        if isinstance(detection_classes, list):  # Default model with decoded strings
            class_label = detection_classes[i]
        else:  # Models returning indices that need to be mapped
            class_id = int(detection_classes[i])
            class_label = class_labels.get(class_id, "Unknown")
        
        detections.append({
            "box": detection_boxes[i].tolist(),
            "class_label": class_label,
            "score": float(detection_scores[i])
        })

    output = {
        "num_objects": num_detections,
        "detections": detections
    }

    return json.dumps(output, indent=2)





def detect_img(image_url, model_url):
    start_time = time.time()
    image_data = download_and_resize_image(image_url, 1920, 1080)
    detector = load_model(model_url)  # Use the new load_model function
    # Ensure class labels are loaded outside of this function or passed here
    result = run_detector(detector, image_data, model_url, class_labels)
    end_time = time.time()
    print("Inference time:", end_time - start_time)
    print(result)



# Argument parser setup
parser = argparse.ArgumentParser(description="Run a TensorFlow detector model on an image from a URL.")
parser.add_argument("--url", required=True, help="URL of the image to process.")
parser.add_argument("--model", default="https://tfhub.dev/google/openimages_v4/ssd/mobilenet_v2/1", help="URL of the TensorFlow Hub model to use.")
args = parser.parse_args()

# Starting detection
print(f"Starting to detect image: {args.url}")
# Load class labels
class_labels = load_class_labels('/data/efficientdet_classes.json')

detect_img(args.url, args.model)