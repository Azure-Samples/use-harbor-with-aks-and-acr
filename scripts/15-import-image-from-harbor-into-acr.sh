#!/bin/bash

# Variables
source ./00-variables.sh

# Import images from Harbor into Azure Container Registry
for repository in ${importRepositories[@]}; do
  echo "Importing [$repository] repository from the [$harborHostname] Harbor into the [$acrName] container registry..."
  az acr import \
    --name $acrName \
    --resource-group $acrResourceGroupName \
    --source $harborHostname/$importProject/$repository \
    --image harbor/$repository \
    --username $harborAdminUsername \
    --password $harborAdminPassword \
    --force &>/dev/null

  if [[ $? == 0 ]]; then
    echo "[$repository] repository successfully imported from the [$harborHostname] Harbor into the [$acrName] container registry"
  else
    echo "Failed to import [$repository] repository from the [$harborHostname] Harbor into the [$acrName] container registry"
    exit
  fi
done