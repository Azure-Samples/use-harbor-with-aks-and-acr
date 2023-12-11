#!/bin/bash

# Variables
source ./00-variables.sh

# Check if the resource group already exists
echo "Checking if [$acrResourceGroupName] resource group actually exists in the [$subscriptionName] subscription..."

az group show --name $acrResourceGroupName &>/dev/null

if [[ $? != 0 ]]; then
  echo "No [$acrResourceGroupName] resource group actually exists in the [$subscriptionName] subscription"
  echo "Creating [$acrResourceGroupName] resource group in the [$subscriptionName] subscription..."

  # Create the resource group
  az group create --name $acrResourceGroupName --location $location 1>/dev/null

  if [[ $? == 0 ]]; then
    echo "[$acrResourceGroupName] resource group successfully created in the [$subscriptionName] subscription"
  else
    echo "Failed to create [$acrResourceGroupName] resource group in the [$subscriptionName] subscription"
    exit
  fi
else
  echo "[$acrResourceGroupName] resource group already exists in the [$subscriptionName] subscription"
fi

# Check if the Azure Container Registry already exists
echo "Checking if [$acrName] Azure Container Registry actually exists in the [$acrResourceGroupName] resource group..."
az acr show \
  --name $acrName \
  --resource-group $acrResourceGroupName &>/dev/null

if [[ $? != 0 ]]; then
  echo "No [$acrName] Azure Container Registry actually exists in the [$acrResourceGroupName] resource group"
  echo "Creating [$acrName] Azure Container Registry in the [$acrResourceGroupName] resource group..."

  # Create the Azure Container Registry
  az acr create \
    --name $acrName \
    --resource-group $acrResourceGroupName \
    --sku $acrSku \
    --allow-exports true \
    --allow-trusted-services true 1>/dev/null

  if [[ $? == 0 ]]; then
    echo "[$acrName] Azure Container Registry successfully created in the [$acrResourceGroupName] resource group"
  else
    echo "Failed to create [$acrName] Azure Container Registry in the [$acrResourceGroupName] resource group"
    exit
  fi
else
  echo "[$acrName] Azure Container Registry already exists in the [$acrResourceGroupName] resource group"
fi