#!/bin/bash

# Variables
source ./00-variables.sh

# Checck if an Azure Container Registry scope map already exists
echo "Checking if [$acrScopeMapName] scope map actually exists in the [$acrName] container registry..."
az acr scope-map show \
  --name $acrScopeMapName \
  --registry $acrName \
  --resource-group $acrResourceGroupName &>/dev/null

if [[ $? != 0 ]]; then
  echo "No [$acrScopeMapName] scope map actually exists in the [$acrName] container registry"
  echo "Creating [$acrScopeMapName] scope map in the [$acrName] container registry..."

  # Create the Azure Container Registry scope map
  az acr scope-map create \
    --name $acrScopeMapName \
    --registry $acrName \
    --resource-group $acrResourceGroupName \
    --description "Scope map for Harbor" &>/dev/null

  if [[ $? == 0 ]]; then
    echo "[$acrScopeMapName] scope map successfully created in the [$acrName] container registry"
  else
    echo "Failed to create [$acrScopeMapName] scope map in the [$acrName] container registry"
    exit
  fi

  # Add the repositories to the Azure Container Registry scope map
  for repository in ${repositories[@]}; do
    echo "Adding [$repository] repository to the [$acrScopeMapName] scope map in the [$acrName] container registry..."
    az acr scope-map update \
      --name $acrScopeMapName \
      --registry $acrName \
      --resource-group $acrResourceGroupName \
      --add-repository $repository content/read content/write metadata/read metadata/write &>/dev/null

    if [[ $? == 0 ]]; then
      echo "[$repository] repository successfully added to the [$acrScopeMapName] scope map in the [$acrName] container registry"
    else
      echo "Failed to add [$repository] repository to the [$acrScopeMapName] scope map in the [$acrName] container registry"
      exit
    fi
  done
else
  echo "[$acrScopeMapName] scope map already exists in the [$acrName] container registry"
fi

# Check if the token already exists
echo "Checking if [$acrUsername] token actually exists in the [$acrName] container registry..."
az acr token show \
  --name $acrUsername \
  --registry $acrName \
  --resource-group $acrResourceGroupName &>/dev/null

if [[ $? != 0 ]]; then
  echo "No [$acrUsername] token actually exists in the [$acrName] container registry"
  echo "Creating [$acrUsername] token in the [$acrName] container registry..."

  # Create the token
  password=$(az acr token create \
    --name $acrUsername \
    --registry $acrName \
    --resource-group $acrResourceGroupName \
    --scope-map $acrScopeMapName \
    --query "credentials.passwords[?name=='password1'].value" \
    --output tsv \
    --only-show-errors)

  if [[ $? == 0 ]]; then
    echo "[$acrUsername] token successfully created in the [$acrName] container registry"
  else
    echo "Failed to create [$acrUsername] token in the [$acrName] container registry"
    exit
  fi
else
  echo "[$acrUsername] token already exists in the [$acrName] container registry"
fi

# Displaying the token
echo "Username: $acrUsername"
echo "Token: $password"