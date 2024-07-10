# Object Detection with Faster R-CNN ResNet50

This repository contains a script for performing object detection using the Faster R-CNN ResNet50 model with TensorFlow. The script downloads the model, preprocesses input images, performs object detection, and optionally draws bounding boxes around detected objects.

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Arguments](#arguments)
- [Example](#example)
- [COCO Labels](#coco-labels)
- [License](#license)

## Requirements

- Python 3.6+
- TensorFlow 2.x
- OpenCV
- Requests
- NumPy

## Installation

1. Clone the repository:

    ```bash
    git clone https://github.com/yourusername/your-repo-name.git
    cd your-repo-name
    ```

2. Install the required packages:

    ```bash
    pip install -r requirements.txt
    ```

## Usage

Run the `main.py` script with the necessary arguments to perform object detection on an image.

```bash
python main.py --image-path <path_to_image> [--include-picture-with-boundingboxes] [--filter <labels>] [--min-confidence <confidence>]
```

## Arguments

- `--image-path`: Required. Path to the input image. Can be a local path or a URL.
- `--include-picture-with-boundingboxes`: Optional. Include the picture with bounding boxes in the output (base64-encoded).
- `--filter`: Optional. Comma-separated list of labels to filter. Only these labels will be included in the output.
- `--min-confidence`: Optional. Minimum confidence for detection. Default is `0.5`.

## Example

To run the script on a local image with a minimum confidence of 0.6 and include the picture with bounding boxes in the output:

```bash
python main.py --image-path ./images/sample.jpg --include-picture-with-boundingboxes --min-confidence 0.6
```

### Output

The script outputs a JSON object with the detected objects. If the `--include-picture-with-boundingboxes` option is specified, it also includes a base64-encoded image with bounding boxes.

### Sample Output

```json
{
    "objects": [
        {
            "label": "person",
            "score": 0.95,
            "bounding_box": [100, 50, 200, 300]
        },
        {
            "label": "car",
            "score": 0.85,
            "bounding_box": [300, 200, 400, 500]
        }
    ],
    "image-base64-encoded": "/9j/4AAQSkZJRgABAQEAAAAAAAD/..."
}
```

To run the script on an image from a URL and filter for specific labels (e.g., person, dog):

```bash
python main.py --image-path https://example.com/sample.jpg --filter person,dog
```

## COCO Labels

The script uses the COCO dataset labels for object detection. The labels are mapped as follows:

```python
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
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.