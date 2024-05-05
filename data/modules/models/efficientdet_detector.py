import tensorflow as tf
import kagglehub
import json
from modules.models.base_detector import BaseDetector

class EfficientDetDetector(BaseDetector):
    def __init__(self, model_url: str, label_path: str):
        """
        Initializes the EfficientDetDetector with a model loaded from the specified URL,
        and loads class labels from a JSON file.

        Args:
            model_url (str): URL of the TensorFlow model to load.
            label_path (str): Path to the JSON file containing class labels.
        """
        self.model = self.load_model(model_url)
        self.class_labels = self.load_class_labels(label_path)

    def load_model(self, model_url: str):
        """
        Load the EfficientDet model from the specified URL.

        Args:
            model_url (str): URL of the EfficientDet model to load.

        Returns:
            TensorFlow model: Loaded model.
        """
        model_path = kagglehub.model_download(model_url)
        return tf.saved_model.load(model_path)

    def load_class_labels(self, json_filepath: str) -> dict:
        """
        Load class labels from a JSON file.

        Args:
            json_filepath (str): Path to the JSON file containing class labels.

        Returns:
            dict: Dictionary mapping class indices to class labels.
        """
        with open(json_filepath, 'r') as file:
            class_labels = json.load(file)
        return {int(k): v for k, v in class_labels.items()}

    def run(self, image_tensor: tf.Tensor) -> dict:
        """
        Run the detector on the input image tensor and return detection results.

        Args:
            image_tensor (tf.Tensor): Image tensor to run the detector on.

        Returns:
            dict: Detection results including boxes, classes, and scores.
        """
        result = self.model(tf.expand_dims(image_tensor, axis=0))
        detections = []

        detection_classes = result['detection_classes'][0].numpy()
        detection_boxes = result['detection_boxes'][0].numpy()
        detection_scores = result['detection_scores'][0].numpy()
        num_detections = int(result['num_detections'].numpy())

        for i in range(num_detections):
            detections.append({
                "box": detection_boxes[i].tolist(),
                "class_id": int(detection_classes[i]),
                "score": float(detection_scores[i])
            })

        return {
            "num_objects": num_detections,
            "detections": detections
        }

    def format_detections(self, detections: dict) -> str:
        """
        Format detection results into a JSON-like string with class labels.

        Args:
            detections (dict): Detection results from the `run` method.

        Returns:
            str: JSON-formatted string of detection results.
        """
        for detection in detections['detections']:
            class_id = detection["class_id"]
            detection["class_label"] = self.class_labels.get(class_id, "Unknown")
            del detection["class_id"]

        return json.dumps(detections, indent=2)
