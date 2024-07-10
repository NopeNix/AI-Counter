# Object Detection with OpenCV and YOLOv3

This repository contains a script (`main_yolo.py`) that performs object detection on images using the YOLOv3 model. The script can download the model if it is not already present, process an image, and output the detected objects in JSON format. Optionally, it can also include the image with bounding boxes drawn around the detected objects.

## Requirements

- Python 3.6 or higher
- OpenCV
- NumPy
- Requests

## Installation

1. **Clone the repository**:
   ```sh
   git clone https://github.com/your-repository/object-detection-yolo.git
   cd object-detection-yolo
   ```

2. **Create a virtual environment** (optional but recommended):
   ```sh
   python -m venv venv
   source venv/bin/activate  # On Windows use `venv\Scripts\activate`
   ```

3. **Install the dependencies**:
   ```sh
   pip install opencv-python-headless numpy requests
   ```

## Usage

### Command-Line Arguments

- `--image-path`: (Required) Path to the input image. Can be a local file path or a URL.
- `--include-picture-with-boundingboxes`: (Optional) If specified, includes the image with bounding boxes in the output.
- `--filter`: (Optional) Comma-separated list of labels to filter. For example, `--filter "person,car"` will only return the labels that are `person` or `car`.
- `--min-confidence`: (Optional) Minimum confidence for the model to consider the object detected. Default is `0.5`.

### Example Usage

```sh
python main_yolo.py --image-path http://webcam.wildwakeski.de/webcam_gross.jpg?ver=1656681652 --include-picture-with-boundingboxes --filter "person,car" --min-confidence 0.1
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

## Model

The script uses the YOLOv3 model trained on the COCO dataset. If the model is not found in the specified directory, it will automatically download and extract it.

## Troubleshooting

- **Error: Model file does not exist after extraction**:
  Ensure that the model is correctly downloaded and extracted. The script logs the directory structure after extraction for debugging purposes.

- **Failed to download the image**:
  Ensure that the URL is correct and accessible. Check your internet connection.

## License

This project is licensed under the MIT License.
```

### Explanation
1. **Overview**: Provides a brief description of the script and its functionality.
2. **Requirements**: Lists the necessary Python packages.
3. **Installation**: Provides steps to set up the environment and install dependencies.
4. **Usage**: Explains the command-line arguments and provides example usage.
5. **Output**: Describes the output format with a sample output.
6. **Model**: Information about the model used.
7. **Troubleshooting**: Common issues and their solutions.
8. **License**: License information.