#@title Imports and function definitions

# For running inference on the TF-Hub module.
import tensorflow as tf

import tensorflow_hub as hub

# For downloading the image.
import matplotlib.pyplot as plt
import tempfile
from six.moves.urllib.request import urlopen
from six import BytesIO

# For drawing onto the image.
import numpy as np
from PIL import Image
from PIL import ImageColor
from PIL import ImageDraw
from PIL import ImageFont
from PIL import ImageOps

# For measuring the inference time.
import time

# Print Tensorflow version
print(tf.__version__)

# Check available GPU devices.
print("The following GPU devices are available: %s" % tf.test.gpu_device_name())

# Function Download and Resize Image
def download_and_resize_image(url, new_width=256, new_height=256,
                              display=False):
  _, filename = tempfile.mkstemp(suffix=".jpg")
  response = urlopen(url)
  image_data = response.read()
  image_data = BytesIO(image_data)
  pil_image = Image.open(image_data)
  pil_image = ImageOps.fit(pil_image, (new_width, new_height), Image.LANCZOS)
  pil_image_rgb = pil_image.convert("RGB")
  pil_image_rgb.save(filename, format="JPEG", quality=90)
  print("Image downloaded to %s." % filename)
  return filename

# Select which Model to use:
#   - FasterRCNN+InceptionResNet V2: high accuracy,
#   - ssd+mobilenet V2: small and fast.
module_handle = "https://tfhub.dev/google/openimages_v4/ssd/mobilenet_v2/1" #@param ["https://tfhub.dev/google/openimages_v4/ssd/mobilenet_v2/1", "https://tfhub.dev/google/faster_rcnn/openimages_v4/inception_resnet_v2/1"]

detector = hub.load(module_handle).signatures['default']


# Function to load image
def load_img(path):
  img = tf.io.read_file(path)
  img = tf.image.decode_jpeg(img, channels=3)
  return img
     

import json

def run_detector(detector, path):
    img = load_img(path)
    converted_img = tf.image.convert_image_dtype(img, tf.float32)[tf.newaxis, ...]
    result = detector(converted_img)
    result = {key: value.numpy() for key, value in result.items()}
    num_detections = len(result["detection_scores"])
    
    detections = []
    for i in range(num_detections):
        detection = {
            "object": result["detection_class_entities"][i].decode("utf-8"),
            "confidence": float(result["detection_scores"][i])
        }
        detections.append(detection)
    
    output = {
        "num_objects": num_detections,
        "detections": detections
    }
    
    print(json.dumps(output, indent=2))
  
  

def detect_img(image_url):
  start_time = time.time()
  image_path = download_and_resize_image(image_url, 1920, 1080)
  run_detector(detector, image_path)
  end_time = time.time()
  print("Inference time:",end_time-start_time)

import sys
print ("Starting to detect image: ", sys.argv[1])
detect_img(sys.argv[1])