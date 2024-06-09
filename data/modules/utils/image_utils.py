import cv2
from PIL import Image
from io import BytesIO
from urllib.request import urlopen
import tensorflow as tf

class ImageProcessor:
    @staticmethod
    def download_and_resize_image(url: str, max_width: int = 1920, max_height: int = 1080) -> Image.Image:
        """
        Download an image from the given URL and resize it as necessary.

        Args:
            url (str): URL of the image to download.
            max_width (int): Maximum width of the resized image.
            max_height (int): Maximum height of the resized image.

        Returns:
            PIL.Image.Image: The resized image, or None if an error occurs.
        """
        try:
            response = urlopen(url)
            image_data = BytesIO(response.read())
        except Exception as e:
            print(f"Error downloading the image from {url}: {e}")
            return None

        try:
            image = Image.open(image_data)
        except Exception as e:
            print(f"Error opening the image data: {e}")
            return None

        if image.width > max_width or image.height > max_height:
            ratio = min(max_width / image.width, max_height / image.height)
            image = image.resize(
                (int(image.width * ratio), int(image.height * ratio)),
                Image.Resampling.LANCZOS
            )

        return image

    @staticmethod
    def load_img_from_memory(image: Image.Image, model_url: str) -> tf.Tensor:
        """
        Convert a PIL image to a TensorFlow tensor.

        Args:
            image (PIL.Image.Image): The input image to convert.
            model_url (str): URL of the TensorFlow model to adjust processing.

        Returns:
            tf.Tensor: Tensor representation of the image.
        """
        # Specify the format manually if the format is missing
        format_to_use = image.format if image.format else 'JPEG'

        # Convert the PIL image to bytes
        output = BytesIO()
        image.save(output, format=format_to_use)
        image_bytes = output.getvalue()
        # Decode the image into a tensor
        img = tf.io.decode_image(image_bytes, channels=3, expand_animations=False)

        # Adjust tensor type based on model
        if "efficientdet" in model_url:
            # EfficientDet expects uint8
            img = tf.cast(img, tf.uint8)
        else:
            # Default model expects float32 with normalized values
            img = tf.image.convert_image_dtype(img, tf.float32)

        return img
    
    @staticmethod
    def draw_bounding_boxes(image_path, bounding_boxes, labels=None, normalized=True):
        """
        Draw bounding boxes on the image.
        
        Args:
            image_path (str): Path to the input image.
            bounding_boxes (list of tuples): List of bounding boxes.
                Each tuple can be (x1, y1, x2, y2).
            labels (list of str): List of labels for the bounding boxes.
            normalized (bool): Whether the bounding boxes are normalized.

        Returns:
            Image.Image: The image with bounding boxes drawn on it.
        """
        # Load the image
        image = cv2.imread(image_path)
        if image is None:
            raise ValueError(f"Unable to load image from path: {image_path}")
        image_height, image_width = image.shape[:2]

        # Convert bounding boxes if they are normalized
        if normalized:
            bounding_boxes_pixel = [
                (int(x1 * image_width), int(y1 * image_height), int(x2 * image_width), int(y2 * image_height))
                for (x1, y1, x2, y2) in bounding_boxes
            ]
        else:
            bounding_boxes_pixel = bounding_boxes

        # Draw bounding boxes and labels on the image
        for i, bbox in enumerate(bounding_boxes_pixel):
            if len(bbox) == 4:
                x1, y1, x2, y2 = bbox
            else:
                raise ValueError("Bounding box format is incorrect. Must be (x1, y1, x2, y2)")

            # Draw the bounding box
            cv2.rectangle(image, (x1, y1), (x2, y2), (255, 0, 0), 2)

            # Draw the label
            if labels:
                label = labels[i]
                (text_width, text_height), baseline = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.5, 1)
                cv2.rectangle(image, (x1, y1 - text_height - baseline), (x1 + text_width, y1), (255, 0, 0), cv2.FILLED)
                cv2.putText(image, label, (x1, y1 - baseline), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1, cv2.LINE_AA)

        # Convert the image back to PIL format
        image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        result_image = Image.fromarray(image_rgb)
        return result_image