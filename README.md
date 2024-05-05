# AI-Object-Counter
- Counts Objects on a Image and writes the Count to a MariaDB Database. 
- Configurable via Web Interface
- REST API with Swagger Documentation for easy external Data Access.

# Running the `main.py` file
`python script.py --url image_url --model model_path`

The `model_path` is optional. By default, it uses the `https://tfhub.dev/google/openimages_v4/ssd/mobilenet_v2/1` model. You can also try the `tensorflow/efficientdet/tensorFlow2/d0` model.