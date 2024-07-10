import tensorflow as tf
import numpy as np
import cv2
import base64
import json
import argparse
import os
import requests
import tarfile
from io import BytesIO

# COCO labels mapping
COCO_LABELS = {
    1: "person", 2: "bicycle", 3: "car", 4: "motorcycle", 5: "airplane", 6: "bus",
    7: "train", 8: "truck", 9: "boat", 10: "traffic light", 11: "fire hydrant",
    13: "stop sign", 14: "parking meter", 15: "bench", 16: "bird", 17: "cat",
    18: "dog", 19: "horse", 20: "sheep", 21: "cow", 22: "elephant", 23: "bear",
    24: "zebra", 25: "giraffe", 27: "backpack", 28: "umbrella", 31: "handbag",
    32: "tie", 33: "suitcase", 34: "frisbee", 35: "skis", 36: "snowboard",
    37: "sports ball", 38: "kite", 39: "baseball bat", 40: "baseball glove",
    41: "skateboard", 42: "surfboard", 43: "tennis racket", 44: "bottle",
    46: "wine glass", 47: "cup", 48: "fork", 49: "knife", 50: "spoon", 51: "bowl",
    52: "banana", 53: "apple", 54: "sandwich", 55: "orange", 56: "broccoli",
    57: "carrot", 58: "hot dog", 59: "pizza", 60: "donut", 61: "cake",
    62: "chair", 63: "couch", 64: "potted plant", 65: "bed", 67: "dining table",
    70: "toilet", 72: "tv", 73: "laptop", 74: "mouse", 75: "remote", 76: "keyboard",
    77: "cell phone", 78: "microwave", 79: "oven", 80: "toaster", 81: "sink",
    82: "refrigerator", 84: "book", 85: "clock", 86: "vase", 87: "scissors",
    88: "teddy bear", 89: "hair drier", 90: "toothbrush"
}

MODEL_URL = 'http://download.tensorflow.org/models/object_detection/tf2/20200711/ssd_mobilenet_v2_fpnlite_320x320_coco17_tpu-8.tar.gz'
MODEL_DIR = 'ssd_mobilenet_v2_fpnlite_320x320'
MODEL_PATH = os.path.join(MODEL_DIR, 'ssd_mobilenet_v2_fpnlite_320x320_coco17_tpu-8', 'saved_model')

def download_and_extract_model():
    if not os.path.exists(MODEL_DIR):
        os.makedirs(MODEL_DIR)
    response = requests.get(MODEL_URL, stream=True)
    if response.status_code == 200:
        tar_file = tarfile.open(fileobj=BytesIO(response.content), mode="r:gz")
        tar_file.extractall(path=MODEL_DIR)
        tar_file.close()
    else:
        raise ValueError(f"Failed to download the model. Status code: {response.status_code}")

def load_model():
    if not os.path.exists(MODEL_PATH):
        download_and_extract_model()
    if not os.path.exists(MODEL_PATH):
        print(f"Model directory {MODEL_PATH} does not exist after extraction.")
        print("Directory structure after extraction:")
        for root, dirs, files in os.walk(MODEL_DIR):
            print(root, dirs, files)
        raise FileNotFoundError(f"Model directory {MODEL_PATH} does not exist after extraction.")
    model = tf.saved_model.load(MODEL_PATH)
    return model

def preprocess_image(image_path):
    if image_path.startswith('http://') or image_path.startswith('https://'):
        response = requests.get(image_path)
        if response.status_code != 200:
            raise ValueError(f"Failed to download the image from {image_path}")
        image_data = np.asarray(bytearray(response.content), dtype="uint8")
        image = cv2.imdecode(image_data, cv2.IMREAD_COLOR)
    else:
        if not os.path.exists(image_path):
            raise FileNotFoundError(f"Image file not found at {image_path}")
        image = cv2.imread(image_path)
    
    if image is None:
        raise ValueError(f"Failed to read the image from {image_path}")
    
    image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    input_tensor = tf.convert_to_tensor(image_rgb)
    input_tensor = input_tensor[tf.newaxis, ...]
    return image, input_tensor

def detect_objects(model, input_tensor, min_confidence, filter_labels):
    detections = model(input_tensor)
    bbox = detections['detection_boxes'][0].numpy()
    class_labels = detections['detection_classes'][0].numpy().astype(np.int32)
    scores = detections['detection_scores'][0].numpy()

    filtered_objects = []
    for i in range(len(scores)):
        if scores[i] >= min_confidence:
            label = COCO_LABELS.get(class_labels[i], 'unknown')
            if not filter_labels or label in filter_labels:
                filtered_objects.append({
                    'label': label,
                    'score': float(scores[i]),
                    'bounding_box': [float(val) for val in bbox[i]]
                })
    return filtered_objects

def draw_bounding_boxes(image, objects):
    for obj in objects:
        ymin, xmin, ymax, xmax = obj['bounding_box']
        (left, right, top, bottom) = (xmin * image.shape[1], xmax * image.shape[1],
                                      ymin * image.shape[0], ymax * image.shape[0])
        cv2.rectangle(image, (int(left), int(top)), (int(right), int(bottom)), (0, 255, 0), 2)
        
        # Improved text rendering
        label = f"{obj['label']}: {obj['score']:.2f}"
        (label_width, label_height), baseline = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.7, 2)
        top = max(int(top), label_height)
        
        # Draw a filled rectangle behind the text
        cv2.rectangle(image, (int(left), int(top) - label_height - 10), (int(left) + label_width, int(top)), (0, 255, 0), cv2.FILLED)
        cv2.putText(image, label, (int(left), int(top) - 5), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 0), 2, cv2.LINE_AA)
    
    _, buffer = cv2.imencode('.jpg', image)
    jpg_as_text = base64.b64encode(buffer).decode('utf-8')
    return jpg_as_text

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--image-path', required=True, help='Path to the input image')
    parser.add_argument('--include-picture-with-boundingboxes', action='store_true', help='Include picture with bounding boxes in the output')
    parser.add_argument('--filter', type=str, default='', help='Comma-separated list of labels to filter')
    parser.add_argument('--min-confidence', type=float, default=0.5, help='Minimum confidence for detection')
    args = parser.parse_args()

    filter_labels = [label.strip() for label in args.filter.split(',')] if args.filter else []

    try:
        model = load_model()
    except (FileNotFoundError, ValueError) as e:
        print(f"Error: {e}")
        return

    try:
        image, input_tensor = preprocess_image(args.image_path)
    except (FileNotFoundError, ValueError) as e:
        print(f"Error: {e}")
        return

    objects = detect_objects(model, input_tensor, args.min_confidence, filter_labels)

    result = {'objects': objects}
    if args.include_picture_with_boundingboxes:
        image_with_boxes = draw_bounding_boxes(image, objects)
        result['image-base64-encoded'] = image_with_boxes

    print(json.dumps(result, indent=4))

if __name__ == '__main__':
    main()