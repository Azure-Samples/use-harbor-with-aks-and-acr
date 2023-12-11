#!/bin/bash

# Variables
source ./00-variables.sh

# Run the docker container
docker run -it -d --name flask-app --rm -p 8888:8888 $imageName:$tag 