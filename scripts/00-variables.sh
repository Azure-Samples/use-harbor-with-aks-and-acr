#!/bin/bash

# Azure Subscription and Tenant
subscriptionId=$(az account show --query id --output tsv)
subscriptionName=$(az account show --query name --output tsv)
tenantId=$(az account show --query tenantId --output tsv)
harborResourceGroupName="MikiRG"
location="eastus2"

# Harbor
harborNamespace="harbor"
harborRepoName="harbor"
harborChartName="harbor"
harborReleaseName="harbor"
harborRepoUrl="https://helm.goharbor.io"
harborTlsSecretName="harbor-tls"
harborIngressClassName="nginx"
harborExposeType="ingress"
harborRegistryStorageClass="managed-csi-premium"
harborAdminUsername="admin"
harborAdminPassword="admin"

# Store size
registrySize="256Gi"
jobserviceJobLogSize="8Gi"
databaseSize="8Gi"
redisSize="8Gi"
trivySize="8Gi"

# Replica Count
portalReplicaCount=3
coreReaplicaCount=3
jobserviceReplicaCount=3
registryReplicaCount=3
trivyReplicaCount=3

# Certificate Manager
certManagerNamespace="cert-manager"
certManagerRepoName="jetstack"
certManagerRepoUrl="https://charts.jetstack.io"
certManagerChartName="cert-manager"
certManagerReleaseName="cert-manager"
certManagerClusterIssuer="letsencrypt-nginx"
certManagerAcmeChallengeType="http01"
email="paolos@microsoft.com"
clusterIssuer="letsencrypt-nginx"
template="cluster-issuer.yml"

# NGINX Ingress Controller
nginxNamespace="ingress-basic"
nginxRepoName="ingress-nginx"
nginxRepoUrl="https://kubernetes.github.io/ingress-nginx"
nginxChartName="ingress-nginx"
nginxReleaseName="nginx-ingress"
nginxIngressClassName="nginx"
nginxReplicaCount=3

# Azure DNS Zone
dnsZoneName="babosbird.com"
dnsZoneResourceGroupName="dnsresourcegroup"
harborSubdomain="miaharbor"
harborHostname="${harborSubdomain,,}.${dnsZoneName,,}"
sampleSubdomain="tanflaskapp"
sampleHostname="${sampleSubdomain,,}.${dnsZoneName,,}"

# Virtual Network
virtualNetworkName="MikiAksVnet"
virtualNetworkAddressPrefix="10.0.0.0/8"

# Subnets
postgreSqlSubnetName="SqlSubnet"
postgreSqlSubnetPrefix="10.244.0.0/24"
defaultSubnetName="VmSubnet"
defaultPrefix="10.243.1.0/24"

# Private DNS Zones
postgreSqlPrivateDnsZoneName="harbor.postgres.database.azure.com"
postgreSqlPrivateDnsZoneVirtualNetworkLinkName="LinkTo${virtualNetworkName}"
redisPrivateDnsZoneName="privatelink.redis.cache.windows.net"
redisPrivateDnsZoneVirtualNetworkLinkName="LinkTo${virtualNetworkName}"

# Azure Database for PostgreSQL flexible server
postgreSqlServerName="MikiPostgreSQLServer"
postgreSqlActiveDirectoryAuth="Enabled"
postgreSqlAdminUsername="azadmin"
postgreSqlAdminPassword="P@ssw0rd1234"
postgreSqlSkuName="Standard_D2s_v3"
postgreSqlStorageSize=1024
postgreSqlVersion=15
postgreSqlDatabaseName="registry"

# Azure Cache for Redis
redisCacheName="MikiRedisCache"
redisCacheSku="Standard"
redisCacheVmSize="C1"
redisCachePrivateEndpointName="RedisCachePrivateEndpoint"
redisCachePrivateDnsZoneGroupName="RedisCache"

# Azure Container Registry
acrName="TanAcr"
acrResourceGroupName="TanRG"
acrSku="Standard"
acrUsername="harbor"
acrScopeMapName="harbor-scope-map"
repositories=("chat" "doc")
moreRepositories=("harbor/flaskapp")
importProject="private"
importRepositories=("ubuntu:latest" "python:latest")

# Image
imageName="flaskapp"
tag="1.0"
harborProject="private"
imagePullPolicy="IfNotPresent" # Always, Never, IfNotPresent

# Others
dockerEmail="paolos@microsoft.com"

# Kubernetes
sampleNamespace="flaskapp"
managedCsiPremiumZrsStorageClassName="managed-csi-premium-zrs"
azureFilePremiumZrsStorageClassName="azurefile-csi-premium-zrs"