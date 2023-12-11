#!/bin/bash

# For more information, see:
# https://artifacthub.io/packages/helm/harbor/harbor
# https://github.com/goharbor/harbor
# https://github.com/goharbor/harbor-helm

# Variables
source ./00-variables.sh

# Check if the Harbor repository is not already added
result=$(helm repo list | grep $harborRepoName | awk '{print $1}')

if [[ -n $result ]]; then
  echo "[$harborRepoName] Helm repo already exists"
else
  # Add the ingress-Harbor repository
  echo "Adding [$harborRepoName] Helm repo..."
  helm repo add $harborRepoName $harborRepoUrl
fi

# Update your local Helm chart repository cache
echo 'Updating Helm repos...'
helm repo update

# Use Helm to deploy Harbor
result=$(helm list -n $harborNamespace | grep $harborReleaseName | awk '{print $1}')

if [[ -n $result ]]; then
  echo "[$harborReleaseName] release already exists in the [$harborNamespace] namespace"

  # Upgrade Harbor
  echo "Upgrading [$harborReleaseName] release in the [$harborNamespace] namespace..."
  helm upgrade $harborReleaseName $harborRepoName/$harborChartName \
    --install \
    --create-namespace \
    --namespace $harborNamespace \
    --set externalURL=https://$harborHostname \
    --set harborAdminPassword=$harborAdminPassword \
    --set expose.type=$harborExposeType \
    --set expose.tls.certSource=secret \
    --set expose.tls.secret.secretName=$harborTlsSecretName \
    --set expose.ingress.hosts.core=$harborHostname \
    --set expose.ingress.className=$nginxIngressClassName \
    --set expose.ingress.annotations."cert-manager\.io/cluster-issuer"=$certManagerClusterIssuer \
    --set expose.ingress.annotations."cert-manager\.io/acme-challenge-type"=$certManagerAcmeChallengeType \
    --set persistence.enabled=true \
    --set persistence.persistentVolumeClaim.registry.storageClass=$harborRegistryStorageClass \
    --set persistence.persistentVolumeClaim.jobservice.jobLog.storageClass=$harborRegistryStorageClass \
    --set persistence.persistentVolumeClaim.database.storageClass=$harborRegistryStorageClass \
    --set persistence.persistentVolumeClaim.redis.storageClass=$harborRegistryStorageClass \
    --set persistence.persistentVolumeClaim.trivy.storageClass=$harborRegistryStorageClass \
    --set persistence.persistentVolumeClaim.registry.size=$registrySize \
    --set persistence.persistentVolumeClaim.jobservice.jobLog.size=$jobserviceJobLogSize \
    --set persistence.persistentVolumeClaim.database.size=$databaseSize \
    --set persistence.persistentVolumeClaim.redis.size=$redisSize \
    --set persistence.persistentVolumeClaim.trivy.size=$trivySize \
    --set portal.replicas=$portalReplicaCount \
    --set core.replicas=$coreReaplicaCount \
    --set jobservice.replicas=$jobserviceReplicaCount \
    --set registry.replicas=$registryReplicaCount \
    --set trivy.replicas=$trivyReplicaCount
else
  # Install Harbor
  echo "Installing [$harborReleaseName] release in the [$harborNamespace] namespace..."
  helm install $harborReleaseName $harborRepoName/$harborChartName \
    --create-namespace \
    --namespace $harborNamespace \
    --set externalURL=https://$harborHostname \
    --set harborAdminPassword=$harborAdminPassword \
    --set expose.type=$harborExposeType \
    --set expose.tls.certSource=secret \
    --set expose.tls.secret.secretName=$harborTlsSecretName \
    --set expose.ingress.hosts.core=$harborHostname \
    --set expose.ingress.className=$nginxIngressClassName \
    --set expose.ingress.annotations."cert-manager\.io/cluster-issuer"=$certManagerClusterIssuer \
    --set expose.ingress.annotations."cert-manager\.io/acme-challenge-type"=$certManagerAcmeChallengeType \
    --set persistence.enabled=true \
    --set persistence.persistentVolumeClaim.registry.storageClass=$harborRegistryStorageClass \
    --set persistence.persistentVolumeClaim.jobservice.jobLog.storageClass=$harborRegistryStorageClass \
    --set persistence.persistentVolumeClaim.database.storageClass=$harborRegistryStorageClass \
    --set persistence.persistentVolumeClaim.redis.storageClass=$harborRegistryStorageClass \
    --set persistence.persistentVolumeClaim.trivy.storageClass=$harborRegistryStorageClass \
    --set persistence.persistentVolumeClaim.registry.size=$registrySize \
    --set persistence.persistentVolumeClaim.jobservice.jobLog.size=$jobserviceJobLogSize \
    --set persistence.persistentVolumeClaim.database.size=$databaseSize \
    --set persistence.persistentVolumeClaim.redis.size=$redisSize \
    --set persistence.persistentVolumeClaim.trivy.size=$trivySize \
    --set portal.replicas=$portalReplicaCount \
    --set core.replicas=$coreReaplicaCount \
    --set jobservice.replicas=$jobserviceReplicaCount \
    --set registry.replicas=$registryReplicaCount \
    --set trivy.replicas=$trivyReplicaCount
fi

# Get values
helm get values $harborReleaseName --namespace $harborNamespace
