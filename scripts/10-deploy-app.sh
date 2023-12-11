#!/bin/bash

# Variables
source ./00-variables.sh

# Check if namespace exists in the cluster
result=$(kubectl get namespace -o jsonpath="{.items[?(@.metadata.name=='$sampleNamespace')].metadata.name}")

if [[ -n $result ]]; then
  echo "$sampleNamespace namespace already exists in the cluster"
else
  echo "$sampleNamespace namespace does not exist in the cluster"
  echo "creating $sampleNamespace namespace in the cluster..."
  kubectl create namespace $sampleNamespace
fi

# Create secret to store Harbor credentials
result=$(kubectl get secret -n $sampleNamespace -o jsonpath="{.items[?(@.metadata.name=='regcred')].metadata.name}")

if [[ -n $result ]]; then
  echo "regcred secret already exists in the cluster"
else
  echo "regcred secret does not exist in the cluster"
  echo "regcred secret namespace in the cluster..."
  kubectl create secret docker-registry regcred \
    --namespace $sampleNamespace \
    --docker-server=$harborHostname \
    --docker-username=$harborAdminUsername \
    --docker-password=$harborAdminPassword \
    --docker-email=$dockerEmail
fi

# Create deployment
cat deployment.yml |
  yq "(.spec.template.spec.containers[0].image)|="\""$harborHostname/$harborProject/$imageName:$tag"\" |
  yq "(.spec.template.spec.containers[0].imagePullPolicy)|="\""$imagePullPolicy"\" |
  kubectl apply -n $sampleNamespace -f -

# Create service
kubectl apply -f service.yml -n $sampleNamespace

# Create ingress
cat ingress.yml |
  yq "(.spec.tls[0].hosts[0])|="\""$sampleHostname"\" |
  yq "(.spec.rules[0].host)|="\""$sampleHostname"\" |
  kubectl apply -n $sampleNamespace -f -
