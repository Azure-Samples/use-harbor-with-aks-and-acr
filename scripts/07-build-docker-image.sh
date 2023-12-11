#!/bin/bash

# Variables
source ./00-variables.sh

# Build the docker image
docker build -t $imageName:$tag -f ./app/Dockerfile ./app