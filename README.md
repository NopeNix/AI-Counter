# AI-Object-Counter
- Counts specified Objects on a Image and writes the Count to a MariaDB Database. 
- Choose between different Models:
  - [Mobilenet_v2 (by Google)](https://www.kaggle.com/models/google/mobilenet-v2/tensorFlow1/openimages-v4-ssd-mobilenet-v2/1?tfhub-redirect=true) 
  - [Efficientdet (by tensorflow)](https://www.kaggle.com/models/tensorflow/efficientdet/tensorFlow2/d0/1?tfhub-redirect=true)
- GPU Support 
- Configurable via Web Interface
- REST API with Swagger Documentation for easy external Data Access.

# Technology Stack
|Tech|Description|
|----|-----------|
|**Docker**||
|**PowerShell Core**||
|**PowerShell Module Pode**||
|**Python**||
|***... AI Stuff to be filled ...***||

# Quick Start
## Requirements
- docker
- docker-compose
- x64 or ARMv8 System
- min 4 GB free Memory (depending on AI Model)

### 1. Clone this Repository:
```bash
git clone https://github.com/NopeNix/AI-Object-Counter.git
```
### 2. Run docker-compose
(The ```docker-compose.yml``` also works with Portainer)
```bash
docker compose up -d
```
**ALTERNATIVE FOR DEV** use docker compose watch:
```bash
docker compose watch
```
(this will automatically rebuild / sync files when there are changes)

### 3. Access Application
http://localhost:8079

# Misc
## Running the `main.py` file
`python main.py --url image_url --model model_path`

The `model_path` is optional. By default, it uses the `https://tfhub.dev/google/openimages_v4/ssd/mobilenet_v2/1` model. You can also try the `tensorflow/efficientdet/tensorFlow2/d0` model.

## Extra optional arguments
- `--include-picture-with-boundingboxes` : If you want to include the picture with the bounding boxes. This adds a `image-base64-encoded` key with a base64 encoded image encoded in `utf-8`.
- `--filter` : If you want to filter the objects that are detected. For example, `--filter "person,car"` will only return the labels that are `person` or `car` (make sure to check out the labels supported by the models). Separate the labels with a comma, don't use spaces, and don't forget to wrap the labels with quotes.
- `--min-confidence` : The minimum confidence for the model to consider the object detected.
