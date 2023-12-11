#!/bin/bash

# Variables
source ./00-variables.sh

# Login to Harbor
docker login $harborHostname -u $harborAdminUsername -p $harborAdminPassword

# Tag the docker image
docker tag $imageName:$tag $harborHostname/$harborProject/$imageName:$tag

# Push the docker image
docker push $harborHostname/$harborProject/$imageName:$tag