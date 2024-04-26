import time
import json
import argparse
import tensorflow as tf
import tensorflow_hub as hub
from urllib.request import urlopen
from io import BytesIO
from PIL import Image, ImageOps

# Print TensorFlow version and check available GPU devices.
print(tf.__version__)
print(f"The following GPU devices are available: {tf.test.gpu_device_name()}")

def download_and_resize_image(url, max_width=1920, max_height=1080, display=False):
    # Fetch and load the image directly into memory
    response = urlopen(url)
    image_data = BytesIO(response.read())
    pil_image = Image.open(image_data)

    # Get original dimensions
    original_width, original_height = pil_image.size
    
    # Determine whether to resize based on original dimensions
    if original_width > max_width or original_height > max_height:
        ratio = min(max_width / original_width, max_height / original_height)
        new_size = (int(original_width * ratio), int(original_height * ratio))
        pil_image = pil_image.resize(new_size, Image.LANCZOS)
    
    pil_image_rgb = pil_image.convert("RGB")
    
    if display:
        pil_image_rgb.show()

    # Convert the image to bytes and return as BytesIO
    output = BytesIO()
    pil_image_rgb.save(output, format="JPEG", quality=90)
    output.seek(0)  # Rewind the file pointer to the beginning of the stream
    return output

def load_img_from_memory(image_data):
    # Read the image data from a BytesIO object
    image_bytes = image_data.getvalue()
    img = tf.io.decode_image(image_bytes, channels=3)
    return img

def run_detector(detector, image_data):
    img = load_img_from_memory(image_data)
    converted_img = tf.image.convert_image_dtype(img, tf.float32)[tf.newaxis, ...]
    result = detector(converted_img)
    result = {key: value.numpy() for key, value in result.items()}
    num_detections = len(result["detection_scores"])
    
    detections = [
        {
            "object": result["detection_class_entities"][i].decode("utf-8"),
            "confidence": float(result["detection_scores"][i])
        }
        for i in range(num_detections)
    ]

    output = {
        "num_objects": num_detections,
        "detections": detections
    }
    
    return json.dumps(output, indent=2)

def detect_img(image_url, model_url):
    start_time = time.time()
    image_data = download_and_resize_image(image_url, 1920, 1080)
    detector = hub.load(model_url).signatures['default']
    result = run_detector(detector, image_data)
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
detect_img(args.url, args.model)