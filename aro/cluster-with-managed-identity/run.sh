#!/bin/bash

# Azure Red Hat OpenShift Cluster Deployment Script
# Replace the values below with your specific configuration

LOCATION=australiaeast                    # Azure region (e.g., eastus, westeurope, australiaeast)
RESOURCEGROUP=rg-arobicep1                # Name of your existing resource group
CLUSTER=aromicluster                      # Unique name for your ARO cluster
VERSION=4.18.26                           # OpenShift version (check available versions with: az aro get-versions --location <location>)
PULL_SECRET=$(cat ./pull-secret.txt)      # Red Hat pull secret from cloud.redhat.com
DOMAIN=jmitlsp8ebcf3c504e                 # Unique domain prefix (lowercase alphanumeric only)
ARO_RP_SP_OBJECT_ID=$(az ad sp list --display-name "Azure Red Hat OpenShift RP" --query '[0].id' -o tsv)

echo "Creating ARO cluster with the following parameters:"
echo "LOCATION: $LOCATION"
echo "RESOURCEGROUP: $RESOURCEGROUP"
echo "CLUSTER: $CLUSTER"
echo "VERSION: $VERSION"
echo "DOMAIN: $DOMAIN"
echo "ARO_RP_SP_OBJECT_ID: $ARO_RP_SP_OBJECT_ID"
echo "PULL_SECRET: ${PULL_SECRET:0:10}..."  # Print only the first 10 characters for security
echo "Deployment initiated. Monitor the Azure portal for progress."
echo "This deployment typically takes 30-40 minutes to complete."

az deployment group create \
    --name aroDeployment \
    --resource-group $RESOURCEGROUP \
    --template-file deploy-with-mi.bicep \
    --parameters location=$LOCATION \
    --parameters version=$VERSION \
    --parameters clusterName=$CLUSTER \
    --parameters rpObjectId=$ARO_RP_SP_OBJECT_ID \
    --parameters domain=$DOMAIN \
    --parameters pullSecret=$PULL_SECRET

echo ""
echo "Deployment command completed. Check the output above for status."
echo "To monitor deployment progress, run:"
echo "  az deployment group show --name aroDeployment --resource-group $RESOURCEGROUP"