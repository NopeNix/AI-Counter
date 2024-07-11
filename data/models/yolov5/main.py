import torch
import numpy as np
import cv2
import base64
import json
import argparse
import os
import requests
from io import BytesIO

# COCO labels mapping
COCO_LABELS = [
    "person", "bicycle", "car", "motorcycle", "airplane", "bus",
    "train", "truck", "boat", "traffic light", "fire hydrant",
    "stop sign", "parking meter", "bench", "bird", "cat", "dog",
    "horse", "sheep", "cow", "elephant", "bear", "zebra", "giraffe",
    "backpack", "umbrella", "handbag", "tie", "suitcase", "frisbee",
    "skis", "snowboard", "sports ball", "kite", "baseball bat",
    "baseball glove", "skateboard", "surfboard", "tennis racket",
    "bottle", "wine glass", "cup", "fork", "knife", "spoon", "bowl",
    "banana", "apple", "sandwich", "orange", "broccoli", "carrot",
    "hot dog", "pizza", "donut", "cake", "chair", "couch",
    "potted plant", "bed", "dining table", "toilet", "tv", "laptop",
    "mouse", "remote", "keyboard", "cell phone", "microwave", "oven",
    "toaster", "sink", "refrigerator", "book", "clock", "vase",
    "scissors", "teddy bear", "hair drier", "toothbrush"
]

MODEL_URL = 'https://github.com/ultralytics/yolov5/releases/download/v6.0/yolov5s.pt'
MODEL_PATH = 'yolov5s.pt'

def download_yolo_model():
    if not os.path.exists(MODEL_PATH):
        response = requests.get(MODEL_URL, stream=True)
        if response.status_code == 200:
            with open(MODEL_PATH, 'wb') as f:
                f.write(response.content)
        else:
            raise ValueError(f"Failed to download the model. Status code: {response.status_code}")

def load_yolo_model():
    if not os.path.exists(MODEL_PATH):
        download_yolo_model()
    model = torch.hub.load('ultralytics/yolov5', 'custom', path=MODEL_PATH)
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
    
    return image

def detect_objects(model, image, min_confidence, filter_labels):
    results = model(image)
    detections = results.pred[0]

    objects = []
    for *bbox, conf, cls in detections:
        if conf >= min_confidence:
            label = COCO_LABELS[int(cls)]
            if not filter_labels or label in filter_labels:
                objects.append({
                    'label': label,
                    'score': float(conf),
                    'bounding_box': [float(val) for val in bbox]
                })
    return objects

def draw_bounding_boxes(image, objects):
    for obj in objects:
        x1, y1, x2, y2 = obj['bounding_box']
        cv2.rectangle(image, (int(x1), int(y1)), (int(x2), int(y2)), (0, 255, 0), 2)
        
        # Improved text rendering
        label = f"{obj['label']}: {obj['score']:.2f}"
        (label_width, label_height), baseline = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.7, 2)
        y1 = max(int(y1), label_height)
        
        # Draw a filled rectangle behind the text
        cv2.rectangle(image, (int(x1), int(y1) - label_height - 10), (int(x1) + label_width, int(y1)), (0, 255, 0), cv2.FILLED)
        cv2.putText(image, label, (int(x1), int(y1) - 5), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 0), 2, cv2.LINE_AA)
    
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

    model = load_yolo_model()
    try:
        image = preprocess_image(args.image_path)
    except (FileNotFoundError, ValueError) as e:
        print(f"Error: {e}")
        return

    objects = detect_objects(model, image, args.min_confidence, filter_labels)

    result = {'objects': objects}
    if args.include_picture_with_boundingboxes:
        image_with_boxes = draw_bounding_boxes(image, objects)
        result['image-base64-encoded'] = image_with_boxes

    print(json.dumps(result, indent=4))

if __name__ == '__main__':
    main()