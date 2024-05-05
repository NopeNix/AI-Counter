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
        # Convert the PIL image to bytes
        output = BytesIO()
        image.save(output, format=image.format)
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
