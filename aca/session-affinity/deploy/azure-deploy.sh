#!/bin/bash

RG=rg-aca-sticky-sessions
LOCATION=eastus
ACA_NAME=aca-sticky-sessions-demo
IMAGE_NAME=${CONTAINER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}

az group create --name $RG --location $LOCATION
az containerapp env create -n $ENV -g $RG --location $LOCATION

# Deploy the app with external HTTP ingress on port 8080
az containerapp create \
  --name $ACA_NAME \
  --resource-group $RG \
  --environment $ENV \
  --image $IMAGE_NAME \
  --ingress 'external' \
  --target-port 8080

# Ensure single-revision mode (required for stickiness)
az containerapp revision set-mode \
  --name $ACA_NAME \
  --resource-group $RG \
  --mode 'single'

# Scale to 2 or more instances (so you can observe routing)
az containerapp update \
  --name $ACA_NAME \
  --resource-group $RG \
  --min-replicas 2 \
  --max-replicas 2

# Turn session affinity ON
az containerapp ingress sticky-sessions set \
  --name $ACA_NAME \
  --resource-group $RG \
  --affinity 'sticky'

# Optional: Confirm
az containerapp ingress sticky-sessions show \
  --name $ACA_NAME \
  --resource-group $RG

APP_FQDN=$(az containerapp show --name $ACA_NAME --resource-group $RG --query properties.configuration.ingress.fqdn -o tsv)

# use a cookie jar so the affinity cookie is reused:
curl -i -c cookies.txt -b cookies.txt https://$APP_FQDN/whoami
curl -i -c cookies.txt -b cookies.txt https://$APP_FQDN/whoami
curl -i -c cookies.txt -b cookies.txt https://$APP_FQDN/whoami

# To turn session affinity OFF:
# az containerapp ingress sticky-sessions set \
#   --name $ACA_NAME \
#   --resource-group $RG \
#   --affinity 'none'

# test without cookie jar:
# curl -i https://$APP_FQDN/whoami
# curl -i https://$APP_FQDN/whoami
# curl -i https://$APP_FQDN/whoami