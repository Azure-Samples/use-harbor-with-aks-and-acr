#!/bin/bash

# For more information, see:
# https://artifacthub.io/packages/helm/harbor/harbor
# https://github.com/goharbor/harbor
# https://github.com/goharbor/harbor-helm

# Variables
source ./00-variables.sh

# Check if the resource group already exists
echo "Checking if [$harborResourceGroupName] resource group actually exists in the [$subscriptionName] subscription..."

az group show --name $harborResourceGroupName &>/dev/null

if [[ $? != 0 ]]; then
  echo "No [$harborResourceGroupName] resource group actually exists in the [$subscriptionName] subscription"
  echo "Creating [$harborResourceGroupName] resource group in the [$subscriptionName] subscription..."

  # Create the resource group
  az group create --name $harborResourceGroupName --location $location 1>/dev/null

  if [[ $? == 0 ]]; then
    echo "[$harborResourceGroupName] resource group successfully created in the [$subscriptionName] subscription"
  else
    echo "Failed to create [$harborResourceGroupName] resource group in the [$subscriptionName] subscription"
    exit
  fi
else
  echo "[$harborResourceGroupName] resource group already exists in the [$subscriptionName] subscription"
fi

# Check if the server virtual network already exists
echo "Checking if [$virtualNetworkName] virtual network actually exists in the [$harborResourceGroupName] resource group..."
az network vnet show \
  --name $virtualNetworkName \
  --only-show-errors \
  --resource-group $harborResourceGroupName &>/dev/null

if [[ $? != 0 ]]; then
  echo "No [$virtualNetworkName] virtual network actually exists in the [$harborResourceGroupName] resource group"
  echo "Creating [$virtualNetworkName] virtual network in the [$harborResourceGroupName] resource group..."

  # Create the server virtual network
  az network vnet create \
    --name $virtualNetworkName \
    --resource-group $harborResourceGroupName \
    --location $location \
    --address-prefixes $virtualNetworkAddressPrefix \
    --subnet-name $defaultSubnetName \
    --subnet-prefix $defaultSubnetPrefix \
    --only-show-errors 1>/dev/null

  if [[ $? == 0 ]]; then
    echo "[$virtualNetworkName] virtual network successfully created in the [$harborResourceGroupName] resource group"
  else
    echo "Failed to create [$virtualNetworkName] virtual network in the [$harborResourceGroupName] resource group"
    exit
  fi
else
  echo "[$virtualNetworkName] virtual network already exists in the [$harborResourceGroupName] resource group"
fi

# Check if the subnet for Azure Database for PostgreSQL flexible server already exists
echo "Checking if [$postgreSqlSubnetName] backend subnet actually exists in the [$virtualNetworkName] virtual network..."
az network vnet subnet show \
  --name $postgreSqlSubnetName \
  --vnet-name $virtualNetworkName \
  --resource-group $harborResourceGroupName \
  --only-show-errors &>/dev/null

if [[ $? != 0 ]]; then
  echo "No [$postgreSqlSubnetName] backend subnet actually exists in the [$virtualNetworkName] virtual network"
  echo "Creating [$postgreSqlSubnetName] backend subnet in the [$virtualNetworkName] virtual network..."

  # Create the backend subnet
  az network vnet subnet create \
    --name $postgreSqlSubnetName \
    --vnet-name $virtualNetworkName \
    --resource-group $harborResourceGroupName \
    --address-prefix $postgreSqlSubnetPrefix \
    --delegations "Microsoft.DBforPostgreSQL/flexibleServers" \
    --only-show-errors 1>/dev/null

  if [[ $? == 0 ]]; then
    echo "[$postgreSqlSubnetName] backend subnet successfully created in the [$virtualNetworkName] virtual network"
  else
    echo "Failed to create [$postgreSqlSubnetName] backend subnet in the [$virtualNetworkName] virtual network"
    exit
  fi
else
  echo "[$postgreSqlSubnetName] backend subnet already exists in the [$virtualNetworkName] virtual network"
fi

# Retrieve the resource id of the subnet
echo "Retrieving [$postgreSqlSubnetName] backend subnet resource id in the [$virtualNetworkName] virtual network..."
postgreSqlSubnetResourceId=$(az network vnet subnet show \
  --name $postgreSqlSubnetName \
  --vnet-name $virtualNetworkName \
  --resource-group $harborResourceGroupName \
  --query id \
  --output tsv \
  --only-show-errors)

if [[ -z $postgreSqlSubnetResourceId ]]; then
  echo "Failed to retrieve [$postgreSqlSubnetName] backend subnet resource id in the [$virtualNetworkName] virtual network"
  exit
fi

# Check if the private DNS Zone already exists
az network private-dns zone show \
  --name $postgreSqlPrivateDnsZoneName \
  --resource-group $harborResourceGroupName \
  --only-show-errors &>/dev/null

if [[ $? != 0 ]]; then
  echo "No [$postgreSqlPrivateDnsZoneName] private DNS zone actually exists in the [$harborResourceGroupName] resource group"
  echo "Creating [$postgreSqlPrivateDnsZoneName] private DNS zone in the [$harborResourceGroupName] resource group..."

  # Create the private DNS Zone
  az network private-dns zone create \
    --name $postgreSqlPrivateDnsZoneName \
    --resource-group $harborResourceGroupName \
    --only-show-errors 1>/dev/null

  if [[ $? == 0 ]]; then
    echo "[$postgreSqlPrivateDnsZoneName] private DNS zone successfully created in the [$harborResourceGroupName] resource group"
  else
    echo "Failed to create [$postgreSqlPrivateDnsZoneName] private DNS zone in the [$harborResourceGroupName] resource group"
    exit
  fi
else
  echo "[$postgreSqlPrivateDnsZoneName] private DNS zone already exists in the [$harborResourceGroupName] resource group"
fi

# Check if the private DNS Zone virtual network link already exists
az network private-dns link vnet show \
  --name $postgreSqlPrivateDnsZoneVirtualNetworkLinkName \
  --resource-group $harborResourceGroupName \
  --zone-name $postgreSqlPrivateDnsZoneName \
  --only-show-errors &>/dev/null

if [[ $? != 0 ]]; then
  echo "No [$postgreSqlPrivateDnsZoneVirtualNetworkLinkName] private DNS zone virtual network link actually exists in the [$harborResourceGroupName] resource group"

  # Retrieve the client virtual network resource id
  virtualNetworkResourceId=$(az network vnet show \
    --name $virtualNetworkName \
    --resource-group $harborResourceGroupName \
    --only-show-errors \
    --query id \
    --output tsv)

  if [[ -z $virtualNetworkResourceId ]]; then
    echo "Failed to retrieve [$virtualNetworkName] client virtual network resource id in the [$harborResourceGroupName] resource group"
    exit
  fi

  echo "Creating [$postgreSqlPrivateDnsZoneVirtualNetworkLinkName] private DNS zone virtual network link in the [$harborResourceGroupName] resource group..."

  # Create the private DNS Zone virtual network link
  az network private-dns link vnet create \
    --name $postgreSqlPrivateDnsZoneVirtualNetworkLinkName \
    --resource-group $harborResourceGroupName \
    --zone-name $postgreSqlPrivateDnsZoneName \
    --virtual-network $virtualNetworkResourceId \
    --registration-enabled false \
    --only-show-errors 1>/dev/null

  if [[ $? == 0 ]]; then
    echo "[$postgreSqlPrivateDnsZoneVirtualNetworkLinkName] private DNS zone virtual network link successfully created in the [$harborResourceGroupName] resource group"
  else
    echo "Failed to create [$postgreSqlPrivateDnsZoneVirtualNetworkLinkName] private DNS zone virtual network link in the [$harborResourceGroupName] resource group"
    exit
  fi
else
  echo "[$postgreSqlPrivateDnsZoneVirtualNetworkLinkName] private DNS zone virtual network link already exists in the [$harborResourceGroupName] resource group"
fi

# Retrieve the resource id of the private DNS Zone
echo "Retrieving [$postgreSqlPrivateDnsZoneName] private DNS zone resource id in the [$harborResourceGroupName] resource group..."
postgreSqlPrivateDnsZoneResourceId=$(az network private-dns zone show \
  --name $postgreSqlPrivateDnsZoneName \
  --resource-group $harborResourceGroupName \
  --query id \
  --output tsv \
  --only-show-errors)

# Check if Azure Database for PostgreSQL flexible server exists
echo "Checking if [$postgreSqlServerName] Azure Database for PostgreSQL flexible server actually exists in the [$harborResourceGroupName] resource group..."
az postgres flexible-server show \
  --name ${postgreSqlServerName,,} \
  --resource-group $harborResourceGroupName \
  --only-show-errors &>/dev/null

if [[ $? != 0 ]]; then
  echo "No [$postgreSqlServerName] Azure Database for PostgreSQL flexible server exists in the [$harborResourceGroupName] resource group"
  echo "Creating [$postgreSqlServerName] Azure Database for PostgreSQL flexible server in the [$harborResourceGroupName] resource group..."

  # Create Azure Database for PostgreSQL flexible server
  az postgres flexible-server create \
    --name $postgreSqlServerName \
    --resource-group $harborResourceGroupName \
    --location $location \
    --active-directory-auth $postgreSqlActiveDirectoryAuth \
    --sku-name $postgreSqlSkuName \
    --storage-size $postgreSqlStorageSize \
    --version $postgreSqlVersion \
    --admin-user $postgreSqlAdminUsername \
    --admin-password $postgreSqlAdminPassword \
    --database-name $postgreSqlDatabaseName \
    --subnet $postgreSqlSubnetResourceId \
    --private-dns-zone $postgreSqlPrivateDnsZoneResourceId \
    --tags "Environment=Test" "Project=Harbor" "Department=IT" \
    --only-show-errors 1>/dev/null

  if [[ $? == 0 ]]; then
    echo "[$postgreSqlServerName] Azure Database for PostgreSQL flexible server successfully created in the [$harborResourceGroupName] resource group"
  else
    echo "Failed to create [$postgreSqlServerName] Azure Database for PostgreSQL flexible server in the [$harborResourceGroupName] resource group"
    exit
  fi
fi

# Retrieve the fullyQualifiedDomainName of the Azure Database for PostgreSQL flexible server
echo "Retrieving the fullyQualifiedDomainName of the [$postgreSqlServerName] Azure Database for PostgreSQL flexible server in the [$harborResourceGroupName] resource group..."
postgreSqlFullyQualifiedDomainName=$(az postgres flexible-server show \
  --name ${postgreSqlServerName,,} \
  --resource-group $harborResourceGroupName \
  --query fullyQualifiedDomainName \
  --output tsv \
  --only-show-errors)

if [[ -n $postgreSqlFullyQualifiedDomainName ]]; then
  echo "[$postgreSqlFullyQualifiedDomainName] fullyQualifiedDomainName for the [$postgreSqlServerName] Azure Database for PostgreSQL flexible server successfully retrieved"
else
  echo "Failed to retrieve the fullyQualifiedDomainName of the [$postgreSqlServerName] Azure Database for PostgreSQL flexible server in the [$harborResourceGroupName] resource group"
  exit
fi

# Check if the Azure Cache for Redis already exists
echo "Checking if [$redisCacheName] Azure Cache for Redis actually exists in the [$harborResourceGroupName] resource group..."
az redis show \
  --name $redisCacheName \
  --resource-group $harborResourceGroupName \
  --only-show-errors &>/dev/null

if [[ $? != 0 ]]; then
  echo "No [$redisCacheName] Azure Cache for Redis actually exists in the [$harborResourceGroupName] resource group"
  echo "Creating [$redisCacheName] Azure Cache for Redis in the [$harborResourceGroupName] resource group..."

  # Create the Azure Cache for Redis
  az redis create \
    --name $redisCacheName \
    --resource-group $harborResourceGroupName \
    --enable-non-ssl-port \
    --location $location \
    --sku $redisCacheSku \
    --mi-system-assigned \
    --vm-size $redisCacheVmSize \
    --tags "Environment=Test" "Project=Harbor" "Department=IT" \
    --only-show-errors 1>/dev/null

  if [[ $? == 0 ]]; then
    echo "[$redisCacheName] Azure Cache for Redis successfully created in the [$harborResourceGroupName] resource group"
  else
    echo "Failed to create [$redisCacheName] Azure Cache for Redis in the [$harborResourceGroupName] resource group"
    exit
  fi
else
  echo "[$redisCacheName] Azure Cache for Redis already exists in the [$harborResourceGroupName] resource group"
fi

# Retrieve the resource id of the Azure Cache for Redis
echo "Retrieving the resource id of the [$redisCacheName] Azure Cache for Redis in the [$harborResourceGroupName] resource group..."
redisCacheResourceId=$(az redis show \
  --name $redisCacheName \
  --resource-group $harborResourceGroupName \
  --query id \
  --output tsv \
  --only-show-errors)

if [[ -n $redisCacheResourceId ]]; then
  echo "[$redisCacheResourceId] resource id for the [$redisCacheName] Azure Cache for Redis successfully retrieved"
else
  echo "Failed to retrieve the resource id of the [$redisCacheName] Azure Cache for Redis in the [$harborResourceGroupName] resource group"
  exit
fi

# Retrieve the hostname of the Azure Cache for Redis
echo "Retrieving the hostname of the [$redisCacheName] Azure Cache for Redis in the [$harborResourceGroupName] resource group..."
redisCacheHostName=$(az redis show \
  --name $redisCacheName \
  --resource-group $harborResourceGroupName \
  --query hostName \
  --output tsv \
  --only-show-errors)

if [[ -n $redisCacheHostName ]]; then
  echo "[$redisCacheHostName] hostname for the [$redisCacheName] Azure Cache for Redis successfully retrieved"
else
  echo "Failed to retrieve the hostname of the [$redisCacheName] Azure Cache for Redis in the [$harborResourceGroupName] resource group"
  exit
fi

# Retrieve the port of the Azure Cache for Redis
echo "Retrieving the port of the [$redisCacheName] Azure Cache for Redis in the [$harborResourceGroupName] resource group..."
redisCachePort=$(az redis show \
  --name $redisCacheName \
  --resource-group $harborResourceGroupName \
  --query port \
  --output tsv \
  --only-show-errors)

if [[ -n $redisCachePort ]]; then
  echo "[$redisCachePort] port for the [$redisCacheName] Azure Cache for Redis successfully retrieved"
else
  echo "Failed to retrieve the port of the [$redisCacheName] Azure Cache for Redis in the [$harborResourceGroupName] resource group"
  exit
fi

# Retrieve the primary key of the Azure Cache for Redis
echo "Retrieving the primary key of the [$redisCacheName] Azure Cache for Redis in the [$harborResourceGroupName] resource group..."
redisCachePrimaryKey=$(az redis list-keys \
  --name $redisCacheName \
  --resource-group $harborResourceGroupName \
  --query primaryKey \
  --output tsv \
  --only-show-errors)

if [[ -n $redisCachePrimaryKey ]]; then
  echo "[$redisCachePrimaryKey] primary key for the [$redisCacheName] Azure Cache for Redis successfully retrieved"
else
  echo "Failed to retrieve the primary key of the [$redisCacheName] Azure Cache for Redis in the [$harborResourceGroupName] resource group"
  exit
fi

# Check if the private DNS Zone already exists
az network private-dns zone show \
  --name $redisPrivateDnsZoneName \
  --resource-group $harborResourceGroupName \
  --only-show-errors &>/dev/null

if [[ $? != 0 ]]; then
  echo "No [$redisPrivateDnsZoneName] private DNS zone actually exists in the [$harborResourceGroupName] resource group"
  echo "Creating [$redisPrivateDnsZoneName] private DNS zone in the [$harborResourceGroupName] resource group..."

  # Create the private DNS Zone
  az network private-dns zone create \
    --name $redisPrivateDnsZoneName \
    --resource-group $harborResourceGroupName \
    --only-show-errors 1>/dev/null

  if [[ $? == 0 ]]; then
    echo "[$redisPrivateDnsZoneName] private DNS zone successfully created in the [$harborResourceGroupName] resource group"
  else
    echo "Failed to create [$redisPrivateDnsZoneName] private DNS zone in the [$harborResourceGroupName] resource group"
    exit
  fi
else
  echo "[$redisPrivateDnsZoneName] private DNS zone already exists in the [$harborResourceGroupName] resource group"
fi

# Check if the private DNS Zone virtual network link already exists
az network private-dns link vnet show \
  --name $redisPrivateDnsZoneVirtualNetworkLinkName \
  --resource-group $harborResourceGroupName \
  --zone-name $redisPrivateDnsZoneName \
  --only-show-errors &>/dev/null

if [[ $? != 0 ]]; then
  echo "No [$redisPrivateDnsZoneVirtualNetworkLinkName] private DNS zone virtual network link actually exists in the [$harborResourceGroupName] resource group"

  # Retrieve the client virtual network resource id
  virtualNetworkResourceId=$(az network vnet show \
    --name $virtualNetworkName \
    --resource-group $harborResourceGroupName \
    --only-show-errors \
    --query id \
    --output tsv)

  if [[ -z $virtualNetworkResourceId ]]; then
    echo "Failed to retrieve [$virtualNetworkName] client virtual network resource id in the [$harborResourceGroupName] resource group"
    exit
  fi

  echo "Creating [$redisPrivateDnsZoneVirtualNetworkLinkName] private DNS zone virtual network link in the [$harborResourceGroupName] resource group..."

  # Create the private DNS Zone virtual network link
  az network private-dns link vnet create \
    --name $redisPrivateDnsZoneVirtualNetworkLinkName \
    --resource-group $harborResourceGroupName \
    --zone-name $redisPrivateDnsZoneName \
    --virtual-network $virtualNetworkResourceId \
    --registration-enabled false \
    --only-show-errors 1>/dev/null

  if [[ $? == 0 ]]; then
    echo "[$redisPrivateDnsZoneVirtualNetworkLinkName] private DNS zone virtual network link successfully created in the [$harborResourceGroupName] resource group"
  else
    echo "Failed to create [$redisPrivateDnsZoneVirtualNetworkLinkName] private DNS zone virtual network link in the [$harborResourceGroupName] resource group"
    exit
  fi
else
  echo "[$redisPrivateDnsZoneVirtualNetworkLinkName] private DNS zone virtual network link already exists in the [$harborResourceGroupName] resource group"
fi

# Retrieve the resource id of the private DNS Zone
echo "Retrieving [$redisPrivateDnsZoneName] private DNS zone resource id in the [$harborResourceGroupName] resource group..."
redisPrivateDnsZoneResourceId=$(az network private-dns zone show \
  --name $redisPrivateDnsZoneName \
  --resource-group $harborResourceGroupName \
  --query id \
  --output tsv \
  --only-show-errors)

# Check if the private endpoint for the Azure Cache for Redis resource already exists
privateEndpointId=$(az network private-endpoint list \
  --resource-group $harborResourceGroupName \
  --only-show-errors \
  --query "[?name=='$redisCachePrivateEndpointName'].id" \
  --output tsv)

if [[ -z $privateEndpointId ]]; then
  echo "Private endpoint [$redisCachePrivateEndpointName] does not exist"
  echo "Creating a private endpoint for the [$redisCacheName] Azure Cache for Redis..."

  # Create a private endpoint for th Azure Cache for Redis resource
  az network private-endpoint create \
    --name $redisCachePrivateEndpointName \
    --resource-group $harborResourceGroupName \
    --vnet-name $virtualNetworkName \
    --subnet $defaultSubnetName \
    --group-id redisCache \
    --private-connection-resource-id $redisCacheResourceId \
    --connection-name "${redisCacheName}Connection" \
    --only-show-errors 1>/dev/null

  if [[ $? == 0 ]]; then
    echo "Private endpoint successfully created for the [$redisCacheName] Azure Cache for Redis"
  else
    echo "Failed to create a private endpoint for the [$redisCacheName] Azure Cache for Redis"
    exit
  fi
else
  echo "Private endpoint [$redisCachePrivateEndpointName] already exists"
fi

# Check if the Private DNS Zone Group already exists
echo "Checking if [$redisCachePrivateDnsZoneGroupName] Private DNS Zone Group actually exists in the [$redisCachePrivateEndpointName] private endpoint..."
groupResourceId=$(az network private-endpoint dns-zone-group show \
  --name $redisCachePrivateDnsZoneGroupName \
  --endpoint-name $redisCachePrivateEndpointName \
  --resource-group $harborResourceGroupName \
  --only-show-errors \
  --query id \
  --output tsv)

if [[ -z $groupResourceId ]]; then
  echo "No [$redisCachePrivateDnsZoneGroupName] Private DNS Zone Group actually exists in the [$redisCachePrivateEndpointName] private endpoint"
  echo "Creating [$redisCachePrivateDnsZoneGroupName] Private DNS Zone Group in the [$redisCachePrivateEndpointName] private endpoint..."

  # Create the Private DNS Zone Group
  az network private-endpoint dns-zone-group create \
    --name $redisCachePrivateDnsZoneGroupName \
    --endpoint-name $redisCachePrivateEndpointName \
    --resource-group $harborResourceGroupName \
    --private-dns-zone $redisPrivateDnsZoneResourceId \
    --zone-name $redisPrivateDnsZoneName \
    --only-show-errors 1>/dev/null

  if [[ $? == 0 ]]; then
    echo "[$redisCachePrivateDnsZoneGroupName] Private DNS Zone Group successfully created in the [$redisCachePrivateEndpointName] private endpoint"
  else
    echo "Failed to create [$redisCachePrivateDnsZoneGroupName] Private DNS Zone Group in the [$redisCachePrivateEndpointName] private endpoint"
    exit
  fi
else
  echo "[$redisCachePrivateDnsZoneGroupName] Private DNS Zone Group already exists in the [$redisCachePrivateEndpointName] private endpoint"
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
    --set database.type=external \
    --set database.external.host=$postgreSqlFullyQualifiedDomainName \
    --set database.external.port=5432 \
    --set database.external.username=$postgreSqlAdminUsername \
    --set database.external.password=$postgreSqlAdminPassword \
    --set database.external.database=$postgreSqlDatabaseName \
    --set database.external.sslmode=require \
    --set redis.type=external \
    --set redis.external.addr=$redisCacheHostName:$redisCachePort \
    --set redis.external.password=$redisCachePrimaryKey \
    --set persistence.enabled=true \
    --set persistence.persistentVolumeClaim.registry.storageClass=$harborRegistryStorageClass \
    --set persistence.persistentVolumeClaim.jobservice.jobLog.storageClass=$harborRegistryStorageClass \
    --set persistence.persistentVolumeClaim.trivy.storageClass=$harborRegistryStorageClass \
    --set persistence.persistentVolumeClaim.registry.size=$registrySize \
    --set persistence.persistentVolumeClaim.jobservice.jobLog.size=$jobserviceJobLogSize \
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
    --set database.type=external \
    --set database.external.host=$postgreSqlFullyQualifiedDomainName \
    --set database.external.port=5432 \
    --set database.external.username=$postgreSqlAdminUsername \
    --set database.external.password=$postgreSqlAdminPassword \
    --set database.external.database=$postgreSqlDatabaseName \
    --set database.external.sslmode=require \
    --set redis.type=external \
    --set redis.external.addr=$redisCacheHostName:$redisCachePort \
    --set redis.external.password=$redisCachePrimaryKey \
    --set persistence.enabled=true \
    --set persistence.persistentVolumeClaim.registry.storageClass=$harborRegistryStorageClass \
    --set persistence.persistentVolumeClaim.jobservice.jobLog.storageClass=$harborRegistryStorageClass \
    --set persistence.persistentVolumeClaim.trivy.storageClass=$harborRegistryStorageClass \
    --set persistence.persistentVolumeClaim.registry.size=$registrySize \
    --set persistence.persistentVolumeClaim.jobservice.jobLog.size=$jobserviceJobLogSize \
    --set persistence.persistentVolumeClaim.trivy.size=$trivySize \
    --set portal.replicas=$portalReplicaCount \
    --set core.replicas=$coreReaplicaCount \
    --set jobservice.replicas=$jobserviceReplicaCount \
    --set registry.replicas=$registryReplicaCount \
    --set trivy.replicas=$trivyReplicaCount
fi

# Get values
helm get values $harborReleaseName --namespace $harborNamespace
