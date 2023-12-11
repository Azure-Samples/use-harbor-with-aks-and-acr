#!/bin/bash

# For more information, see:
# https://artifacthub.io/packages/helm/harbor/harbor
# https://github.com/goharbor/harbor
# https://github.com/goharbor/harbor-helm

# Variables
source ./00-variables.sh

# Check if the managed-csi-premium-zrs storage class exists
result=$(kubectl get storageclass -o jsonpath="{.items[?(@.metadata.name=='$managedCsiPremiumZrsStorageClassName')].metadata.name}")

if [[ -n $result ]]; then
  echo "$managedCsiPremiumZrsStorageClassName storage class already exists in the cluster"
else
  echo "$managedCsiPremiumZrsStorageClassName storage class does not exist in the cluster"
  echo "creating $managedCsiPremiumZrsStorageClassName storage class in the cluster..."
  kubectl apply -f ./managed-csi-premium-zrs.yml
fi

# Check if the azurefile-csi-premium-zrs storage class exists
result=$(kubectl get storageclass -o jsonpath="{.items[?(@.metadata.name=='$azureFilePremiumZrsStorageClassName')].metadata.name}")

if [[ -n $result ]]; then
  echo "$azureFilePremiumZrsStorageClassName storage class already exists in the cluster"
else
  echo "$azureFilePremiumZrsStorageClassName storage class does not exist in the cluster"
  echo "creating $azureFilePremiumZrsStorageClassName storage class in the cluster..."
  kubectl apply -f ./azurefile-csi-premium-zrs.yml
fi

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
    --set persistence.persistentVolumeClaim.registry.storageClass=$azureFilePremiumZrsStorageClassName \
    --set persistence.persistentVolumeClaim.registry.accessMode=ReadWriteMany \
    --set persistence.persistentVolumeClaim.registry.size=$registrySize \
    --set persistence.persistentVolumeClaim.jobservice.jobLog.storageClass=$azureFilePremiumZrsStorageClassName \
    --set persistence.persistentVolumeClaim.jobservice.accessMode=ReadWriteMany \
    --set persistence.persistentVolumeClaim.jobservice.jobLog.size=$jobserviceJobLogSize \
    --set persistence.persistentVolumeClaim.database.storageClass=$managedCsiPremiumZrsStorageClassName \
    --set persistence.persistentVolumeClaim.database.size=$databaseSize \
    --set persistence.persistentVolumeClaim.redis.storageClass=$managedCsiPremiumZrsStorageClassName \
    --set persistence.persistentVolumeClaim.redis.size=$redisSize \
    --set persistence.persistentVolumeClaim.trivy.storageClass=$azureFilePremiumZrsStorageClassName \
    --set persistence.persistentVolumeClaim.trivy.accessMode=ReadWriteMany \
    --set persistence.persistentVolumeClaim.trivy.size=$trivySize \
    --set portal.replicas=$portalReplicaCount \
    --set core.replicas=$coreReaplicaCount \
    --set jobservice.replicas=$jobserviceReplicaCount \
    --set registry.replicas=$registryReplicaCount \
    --set trivy.replicas=$trivyReplicaCount \
    --set portal.topologySpreadConstraints[0].maxSkew=1 \
    --set portal.topologySpreadConstraints[0].whenUnsatisfiable=ScheduleAnyway \
    --set portal.topologySpreadConstraints[0].topologyKey=topology.kubernetes.io/zone \
    --set portal.topologySpreadConstraints[1].maxSkew=1 \
    --set portal.topologySpreadConstraints[1].whenUnsatisfiable=ScheduleAnyway \
    --set portal.topologySpreadConstraints[1].topologyKey=kubernetes.io/hostname \
    --set core.topologySpreadConstraints[0].maxSkew=1 \
    --set core.topologySpreadConstraints[0].whenUnsatisfiable=ScheduleAnyway \
    --set core.topologySpreadConstraints[0].topologyKey=topology.kubernetes.io/zone \
    --set core.topologySpreadConstraints[1].maxSkew=1 \
    --set core.topologySpreadConstraints[1].whenUnsatisfiable=ScheduleAnyway \
    --set core.topologySpreadConstraints[1].topologyKey=kubernetes.io/hostname \
    --set jobservice.topologySpreadConstraints[0].maxSkew=1 \
    --set jobservice.topologySpreadConstraints[0].whenUnsatisfiable=ScheduleAnyway \
    --set jobservice.topologySpreadConstraints[0].topologyKey=topology.kubernetes.io/zone \
    --set jobservice.topologySpreadConstraints[1].maxSkew=1 \
    --set jobservice.topologySpreadConstraints[1].whenUnsatisfiable=ScheduleAnyway \
    --set jobservice.topologySpreadConstraints[1].topologyKey=kubernetes.io/hostname \
    --set registry.topologySpreadConstraints[0].maxSkew=1 \
    --set registry.topologySpreadConstraints[0].whenUnsatisfiable=ScheduleAnyway \
    --set registry.topologySpreadConstraints[0].topologyKey=topology.kubernetes.io/zone \
    --set registry.topologySpreadConstraints[1].maxSkew=1 \
    --set registry.topologySpreadConstraints[1].whenUnsatisfiable=ScheduleAnyway \
    --set registry.topologySpreadConstraints[1].topologyKey=kubernetes.io/hostname \
    --set trivy.topologySpreadConstraints[0].maxSkew=1 \
    --set trivy.topologySpreadConstraints[0].whenUnsatisfiable=ScheduleAnyway \
    --set trivy.topologySpreadConstraints[0].topologyKey=topology.kubernetes.io/zone \
    --set trivy.topologySpreadConstraints[1].maxSkew=1 \
    --set trivy.topologySpreadConstraints[1].whenUnsatisfiable=ScheduleAnyway \
    --set trivy.topologySpreadConstraints[1].topologyKey=kubernetes.io/hostname \
    --set exporter.topologySpreadConstraints[0].maxSkew=1 \
    --set exporter.topologySpreadConstraints[0].whenUnsatisfiable=ScheduleAnyway \
    --set exporter.topologySpreadConstraints[0].topologyKey=topology.kubernetes.io/zone \
    --set exporter.topologySpreadConstraints[1].maxSkew=1 \
    --set exporter.topologySpreadConstraints[1].whenUnsatisfiable=ScheduleAnyway \
    --set exporter.topologySpreadConstraints[1].topologyKey=kubernetes.io/hostname \
    --set persistence.persistentVolumeClaim.registry.size=$registrySize \
    --set persistence.persistentVolumeClaim.jobservice.size=$jobserviceJobLogSize \
    --set persistence.persistentVolumeClaim.database.size=$databaseSize \
    --set persistence.persistentVolumeClaim.redis.size=$redisSize \
    --set persistence.persistentVolumeClaim.trivy.size=$trivySize
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
    --set persistence.persistentVolumeClaim.registry.storageClass=$azureFilePremiumZrsStorageClassName \
    --set persistence.persistentVolumeClaim.registry.accessMode=ReadWriteMany \
    --set persistence.persistentVolumeClaim.registry.size=$registrySize \
    --set persistence.persistentVolumeClaim.jobservice.jobLog.storageClass=$azureFilePremiumZrsStorageClassName \
    --set persistence.persistentVolumeClaim.jobservice.accessMode=ReadWriteMany \
    --set persistence.persistentVolumeClaim.jobservice.jobLog.size=$jobserviceJobLogSize \
    --set persistence.persistentVolumeClaim.database.storageClass=$managedCsiPremiumZrsStorageClassName \
    --set persistence.persistentVolumeClaim.database.size=$databaseSize \
    --set persistence.persistentVolumeClaim.redis.storageClass=$managedCsiPremiumZrsStorageClassName \
    --set persistence.persistentVolumeClaim.redis.size=$redisSize \
    --set persistence.persistentVolumeClaim.trivy.storageClass=$azureFilePremiumZrsStorageClassName \
    --set persistence.persistentVolumeClaim.trivy.accessMode=ReadWriteMany \
    --set persistence.persistentVolumeClaim.trivy.size=$trivySize \
    --set portal.replicas=$portalReplicaCount \
    --set core.replicas=$coreReaplicaCount \
    --set jobservice.replicas=$jobserviceReplicaCount \
    --set registry.replicas=$registryReplicaCount \
    --set trivy.replicas=$trivyReplicaCount \
    --set portal.topologySpreadConstraints[0].maxSkew=1 \
    --set portal.topologySpreadConstraints[0].whenUnsatisfiable=ScheduleAnyway \
    --set portal.topologySpreadConstraints[0].topologyKey=topology.kubernetes.io/zone \
    --set portal.topologySpreadConstraints[1].maxSkew=1 \
    --set portal.topologySpreadConstraints[1].whenUnsatisfiable=ScheduleAnyway \
    --set portal.topologySpreadConstraints[1].topologyKey=kubernetes.io/hostname \
    --set core.topologySpreadConstraints[0].maxSkew=1 \
    --set core.topologySpreadConstraints[0].whenUnsatisfiable=ScheduleAnyway \
    --set core.topologySpreadConstraints[0].topologyKey=topology.kubernetes.io/zone \
    --set core.topologySpreadConstraints[1].maxSkew=1 \
    --set core.topologySpreadConstraints[1].whenUnsatisfiable=ScheduleAnyway \
    --set core.topologySpreadConstraints[1].topologyKey=kubernetes.io/hostname \
    --set jobservice.topologySpreadConstraints[0].maxSkew=1 \
    --set jobservice.topologySpreadConstraints[0].whenUnsatisfiable=ScheduleAnyway \
    --set jobservice.topologySpreadConstraints[0].topologyKey=topology.kubernetes.io/zone \
    --set jobservice.topologySpreadConstraints[1].maxSkew=1 \
    --set jobservice.topologySpreadConstraints[1].whenUnsatisfiable=ScheduleAnyway \
    --set jobservice.topologySpreadConstraints[1].topologyKey=kubernetes.io/hostname \
    --set registry.topologySpreadConstraints[0].maxSkew=1 \
    --set registry.topologySpreadConstraints[0].whenUnsatisfiable=ScheduleAnyway \
    --set registry.topologySpreadConstraints[0].topologyKey=topology.kubernetes.io/zone \
    --set registry.topologySpreadConstraints[1].maxSkew=1 \
    --set registry.topologySpreadConstraints[1].whenUnsatisfiable=ScheduleAnyway \
    --set registry.topologySpreadConstraints[1].topologyKey=kubernetes.io/hostname \
    --set trivy.topologySpreadConstraints[0].maxSkew=1 \
    --set trivy.topologySpreadConstraints[0].whenUnsatisfiable=ScheduleAnyway \
    --set trivy.topologySpreadConstraints[0].topologyKey=topology.kubernetes.io/zone \
    --set trivy.topologySpreadConstraints[1].maxSkew=1 \
    --set trivy.topologySpreadConstraints[1].whenUnsatisfiable=ScheduleAnyway \
    --set trivy.topologySpreadConstraints[1].topologyKey=kubernetes.io/hostname \
    --set exporter.topologySpreadConstraints[0].maxSkew=1 \
    --set exporter.topologySpreadConstraints[0].whenUnsatisfiable=ScheduleAnyway \
    --set exporter.topologySpreadConstraints[0].topologyKey=topology.kubernetes.io/zone \
    --set exporter.topologySpreadConstraints[1].maxSkew=1 \
    --set exporter.topologySpreadConstraints[1].whenUnsatisfiable=ScheduleAnyway \
    --set exporter.topologySpreadConstraints[1].topologyKey=kubernetes.io/hostname \
    --set persistence.persistentVolumeClaim.registry.size=$registrySize \
    --set persistence.persistentVolumeClaim.jobservice.size=$jobserviceJobLogSize \
    --set persistence.persistentVolumeClaim.database.size=$databaseSize \
    --set persistence.persistentVolumeClaim.redis.size=$redisSize \
    --set persistence.persistentVolumeClaim.trivy.size=$trivySize
fi

# Get values
helm get values $harborReleaseName --namespace $harborNamespace
