#!/bin/bash

echo "=== Azure Container Apps Deployment Script Started at $(date) ==="

# Check required environment variables
if [ -z "$CONTAINER_REGISTRY" ] || [ -z "$IMAGE_NAME" ] || [ -z "$IMAGE_TAG" ]; then
    echo "ERROR: Missing required environment variables: CONTAINER_REGISTRY, IMAGE_NAME, IMAGE_TAG"
    exit 1
fi

# Generate random suffix for unique resource names
RANDOM_SUFFIX=$(openssl rand -hex 3)

RG=rg-aca-sticky-sessions-${RANDOM_SUFFIX}
LOCATION=australiaeast
ENV=env-aca-sticky-sessions-${RANDOM_SUFFIX}
ACA_NAME=aca-sticky-sessions-demo-${RANDOM_SUFFIX}
FULL_IMAGE_NAME=${CONTAINER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}

echo "Using random suffix: $RANDOM_SUFFIX"

echo "Step 1/8: Creating resource group '$RG'..."
az group create --name $RG --location $LOCATION

echo "Step 2/8: Creating container app environment..."
az containerapp env create -n $ENV -g $RG --location $LOCATION

# Deploy the app with external HTTP ingress on port 8080
echo "Step 3/8: Creating container app '$ACA_NAME'..."
az containerapp create \
  --name $ACA_NAME \
  --resource-group $RG \
  --environment $ENV \
  --image $FULL_IMAGE_NAME \
  --ingress 'external' \
  --target-port 8080

# Ensure single-revision mode (required for stickiness)
echo "Step 4/8: Setting single revision mode..."
az containerapp revision set-mode \
  --name $ACA_NAME \
  --resource-group $RG \
  --mode 'single'

# Scale to 2 or more instances (so you can observe routing)
echo "Step 5/8: Scaling to 2 replicas..."
az containerapp update \
  --name $ACA_NAME \
  --resource-group $RG \
  --min-replicas 2 \
  --max-replicas 2

# Turn session affinity ON
echo "Step 6/8: Enabling session affinity..."
az containerapp ingress sticky-sessions set \
  --name $ACA_NAME \
  --resource-group $RG \
  --affinity 'sticky'

# Optional: Confirm
echo "Step 7/8: Confirming session affinity settings..."
az containerapp ingress sticky-sessions show \
  --name $ACA_NAME \
  --resource-group $RG

echo "Step 8/8: Getting app URL and testing..."
APP_FQDN=$(az containerapp show --name $ACA_NAME --resource-group $RG --query properties.configuration.ingress.fqdn -o tsv)
echo "✓ App URL: https://$APP_FQDN"

# Create temp file for cookies outside project directory
COOKIE_JAR=$(mktemp)

echo ""
echo "=== TESTING SCENARIO 1: STICKY SESSIONS ON ==="
echo "NOTE: curl doesn't store cookies by default (unlike web browsers)."
echo "We use -c/-b flags to save/send cookies. See: https://curl.se/docs/http-cookies.html"
echo ""
echo "Testing WITH cookies (should hit the SAME instance each time):"
echo "Request 1:"
curl -s -c "$COOKIE_JAR" -b "$COOKIE_JAR" https://$APP_FQDN/whoami
echo ""
echo "Request 2:"
curl -s -c "$COOKIE_JAR" -b "$COOKIE_JAR" https://$APP_FQDN/whoami
echo ""
echo "Request 3:"
curl -s -c "$COOKIE_JAR" -b "$COOKIE_JAR" https://$APP_FQDN/whoami

echo ""
echo "Testing WITHOUT cookies (even with sticky sessions ON, should hit different instances):"
echo "Request 1:"
curl -s https://$APP_FQDN/whoami
echo ""
echo "Request 2:"
curl -s https://$APP_FQDN/whoami
echo ""
echo "Request 3:"
curl -s https://$APP_FQDN/whoami

echo ""
echo "Turning session affinity OFF..."
az containerapp ingress sticky-sessions set \
  --name $ACA_NAME \
  --resource-group $RG \
  --affinity 'none'

echo ""
echo "=== TESTING SCENARIO 2: STICKY SESSIONS OFF ==="
echo "Testing without cookies (should hit DIFFERENT instances):"
echo "Request 1:"
curl -s https://$APP_FQDN/whoami
echo ""
echo "Request 2:"
curl -s https://$APP_FQDN/whoami
echo ""
echo "Request 3:"
curl -s https://$APP_FQDN/whoami

echo ""
echo "Re-enabling sticky sessions for future use..."
az containerapp ingress sticky-sessions set \
  --name $ACA_NAME \
  --resource-group $RG \
  --affinity 'sticky'

echo ""
echo "✓ Deployment and testing completed successfully at $(date)"
echo "✓ App is running at: https://$APP_FQDN"
echo "✓ Both sticky sessions scenarios tested"

# Clean up temporary cookie file
rm -f "$COOKIE_JAR"
