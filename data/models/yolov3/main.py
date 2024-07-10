import cv2
import numpy as np
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

MODEL_CONFIG_URL = 'https://raw.githubusercontent.com/pjreddie/darknet/master/cfg/yolov3.cfg'
MODEL_WEIGHTS_URL = 'https://pjreddie.com/media/files/yolov3.weights'
MODEL_NAMES_URL = 'https://raw.githubusercontent.com/pjreddie/darknet/master/data/coco.names'
MODEL_DIR = 'yolov3'
CONFIG_PATH = os.path.join(MODEL_DIR, 'yolov3.cfg')
WEIGHTS_PATH = os.path.join(MODEL_DIR, 'yolov3.weights')
NAMES_PATH = os.path.join(MODEL_DIR, 'coco.names')

def download_file(url, path):
    response = requests.get(url, stream=True)
    if response.status_code == 200:
        with open(path, 'wb') as f:
            f.write(response.content)
    else:
        raise ValueError(f"Failed to download the file. Status code: {response.status_code}")

def download_yolo_model():
    if not os.path.exists(MODEL_DIR):
        os.makedirs(MODEL_DIR)
    if not os.path.exists(CONFIG_PATH):
        download_file(MODEL_CONFIG_URL, CONFIG_PATH)
    if not os.path.exists(WEIGHTS_PATH):
        download_file(MODEL_WEIGHTS_URL, WEIGHTS_PATH)
    if not os.path.exists(NAMES_PATH):
        download_file(MODEL_NAMES_URL, NAMES_PATH)

def load_yolo_model():
    if not os.path.exists(CONFIG_PATH) or not os.path.exists(WEIGHTS_PATH):
        download_yolo_model()
    net = cv2.dnn.readNetFromDarknet(CONFIG_PATH, WEIGHTS_PATH)
    return net

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

def detect_objects(net, image, min_confidence, filter_labels):
    (H, W) = image.shape[:2]
    ln = net.getLayerNames()
    ln = [ln[i - 1] for i in net.getUnconnectedOutLayers()]

    blob = cv2.dnn.blobFromImage(image, 1 / 255.0, (416, 416), swapRB=True, crop=False)
    net.setInput(blob)
    layer_outputs = net.forward(ln)

    boxes = []
    confidences = []
    class_ids = []

    for output in layer_outputs:
        for detection in output:
            scores = detection[5:]
            class_id = np.argmax(scores)
            confidence = scores[class_id]
            if confidence > min_confidence:
                box = detection[0:4] * np.array([W, H, W, H])
                (centerX, centerY, width, height) = box.astype("int")
                x = int(centerX - (width / 2))
                y = int(centerY - (height / 2))
                boxes.append([x, y, int(width), int(height)])
                confidences.append(float(confidence))
                class_ids.append(class_id)

    idxs = cv2.dnn.NMSBoxes(boxes, confidences, min_confidence, 0.3)
    objects = []

    if len(idxs) > 0:
        for i in idxs.flatten():
            label = COCO_LABELS[class_ids[i]]
            if not filter_labels or label in filter_labels:
                objects.append({
                    'label': label,
                    'score': confidences[i],
                    'bounding_box': boxes[i]
                })

    return objects

def draw_bounding_boxes(image, objects):
    for obj in objects:
        (x, y, w, h) = obj['bounding_box']
        cv2.rectangle(image, (x, y), (x + w, y + h), (0, 255, 0), 2)
        
        # Improved text rendering
        label = f"{obj['label']}: {obj['score']:.2f}"
        (label_width, label_height), baseline = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.7, 2)
        y = max(y, label_height)
        
        # Draw a filled rectangle behind the text
        cv2.rectangle(image, (x, y - label_height - 10), (x + label_width, y), (0, 255, 0), cv2.FILLED)
        cv2.putText(image, label, (x, y - 5), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 0), 2, cv2.LINE_AA)
    
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

    net = load_yolo_model()
    try:
        image = preprocess_image(args.image_path)
    except (FileNotFoundError, ValueError) as e:
        print(f"Error: {e}")
        return

    objects = detect_objects(net, image, args.min_confidence, filter_labels)

    result = {'objects': objects}
    if args.include_picture_with_boundingboxes:
        image_with_boxes = draw_bounding_boxes(image, objects)
        result['image-base64-encoded'] = image_with_boxes

    print(json.dumps(result, indent=4))

if __name__ == '__main__':
    main()