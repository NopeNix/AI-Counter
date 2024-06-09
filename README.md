# AI-Object-Counter
- Counts Objects on a Image and writes the Count to a MariaDB Database. 
- Configurable via Web Interface
- REST API with Swagger Documentation for easy external Data Access.

# Running the `main.py` file
`python main.py --url image_url --model model_path`

The `model_path` is optional. By default, it uses the `https://tfhub.dev/google/openimages_v4/ssd/mobilenet_v2/1` model. You can also try the `tensorflow/efficientdet/tensorFlow2/d0` model.

## Extra optional arguments
- `--include-picture-with-boundingboxes` : If you want to include the picture with the bounding boxes. This adds a `image-base64-encoded` key with a base64 encoded image encoded in `utf-8`.
- `--filter` : If you want to filter the objects that are detected. For example, `--filter "person,car"` will only return the labels that are `person` or `car` (make sure to check out the labels supported by the models). Separate the labels with a comma, don't use spaces, and don't forget to wrap the labels with quotes.
- `--min-confidence` : The minimum confidence for the model to consider the object detected.
