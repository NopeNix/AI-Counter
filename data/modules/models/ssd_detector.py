import tensorflow as tf
import tensorflow_hub as hub
from modules.models.base_detector import BaseDetector
import json

class SSDDetector(BaseDetector):
    def __init__(self, model_url: str):
        """
        Initializes the SSDDetector with a model loaded from the specified URL.

        Args:
            model_url (str): URL of the TensorFlow model to load.
        """
        self.model = self.load_model(model_url)

    def load_model(self, model_url: str):
        """
        Load the SSD model from the specified URL.

        Args:
            model_url (str): URL of the SSD model to load.

        Returns:
            TensorFlow model: Loaded model.
        """
        return hub.load(model_url).signatures['default']

    def run(self, image_tensor: tf.Tensor) -> str:
        """
        Run the detector on the input image tensor and return formatted detection results.

        Args:
            image_tensor (tf.Tensor): Image tensor to run the detector on.

        Returns:
            str: JSON-formatted string of detection results.
        """
        result = self.model(tf.expand_dims(image_tensor, axis=0))
        detections = []

        if 'detection_class_entities' in result:
            detection_classes = [x.decode("utf-8") for x in result['detection_class_entities'].numpy()]
            detection_boxes = result['detection_boxes'].numpy()
            detection_scores = result['detection_scores'].numpy()
            num_detections = result['detection_scores'].shape[0]
        else:
            raise KeyError("Expected 'detection_class_entities' not found in the model output.")

        for i in range(num_detections):
            detections.append({
                "box": detection_boxes[i].tolist(),
                "class_label": detection_classes[i],
                "score": float(detection_scores[i])
            })

        output = {
            "num_objects": num_detections,
            "detections": detections
        }

        return json.dumps(output, indent=2)
