# Session Affinity Demo

This project demonstrates session affinity (sticky sessions) in Azure Container Apps using a Spring Boot application with Nginx as a load balancer for local testing.

## Local Development and Testing

### Prerequisites

- Docker and Docker Compose
- curl command-line tool
- Azure CLI (for deployment)

### Testing Locally with Nginx Container

1. **Build and run the containers locally:**
   ```bash
   docker compose up --build -d
   ```

2. **Test with sticky sessions (default configuration):**
   
   The default `docker-compose.yml` uses `nginx.roundrobin.conf`. To test sticky sessions, you need to switch to the sticky configuration:
   
   Edit line 23 in `docker-compose.yml` to use:
   ```yaml
   - ./nginx.sticky.conf:/etc/nginx/nginx.conf:ro
   ```
   
   Then restart the containers:
   ```bash
   docker compose down
   docker compose up --build -d
   ```

3. **Test session affinity with cookie jar:**
   
   Run these commands to test that requests stick to the same replica:
   ```bash
   curl -i -c cookies.txt -b cookies.txt http://localhost:8080/whoami
   curl -i -c cookies.txt -b cookies.txt http://localhost:8080/whoami
   curl -i -c cookies.txt -b cookies.txt http://localhost:8080/whoami
   ```
   
   With sticky sessions enabled, you should see:
   - The `hitCountsInThisSession` increment with each request
   - The same `replicaHost` for all requests

4. **Test without sticky sessions:**
   
   To test round-robin load balancing, edit line 23 in `docker-compose.yml` to use:
   ```yaml
   - ./nginx.roundrobin.conf:/etc/nginx/nginx.conf:ro
   ```
   
   Restart the containers and run the same curl commands. You should see different `replicaHost` values as requests are distributed across replicas.

5. **Clean up:**
   ```bash
   docker compose down
   ```

## Building and Publishing Container Images

### Local Build

1. **Build the Docker image:**
   ```bash
   docker build -t aca-affinity:1 .
   ```

### Publishing to Container Registry

Replace the registry URL and image name with your own:

1. **Tag the image for your registry:**
   ```bash
   # For GitHub Container Registry
   docker tag aca-affinity:1 ghcr.io/<your-username>/<image-name>:1
   
   # For Azure Container Registry
   docker tag aca-affinity:1 <your-acr-name>.azurecr.io/<image-name>:1
   
   # For Docker Hub
   docker tag aca-affinity:1 <your-username>/<image-name>:1
   ```

2. **Login to your registry:**
   ```bash
   # For GitHub Container Registry
   echo $GITHUB_TOKEN | docker login ghcr.io -u <your-username> --password-stdin
   
   # For Azure Container Registry
   az acr login --name <your-acr-name>
   
   # For Docker Hub
   docker login
   ```

3. **Push the image:**
   ```bash
   # For GitHub Container Registry
   docker push ghcr.io/<your-username>/<image-name>:1
   
   # For Azure Container Registry
   docker push <your-acr-name>.azurecr.io/<image-name>:1
   
   # For Docker Hub
   docker push <your-username>/<image-name>:1
   ```

## Deploying to Azure Container Apps

### Prerequisites

- Azure CLI installed and logged in
- Docker image published to a container registry

### Environment Variables

Before running the deployment script, set up the required environment variables:

```bash
# Required environment variables
export CONTAINER_REGISTRY="ghcr.io/<your-username>"  # or your ACR/Docker Hub registry
export IMAGE_NAME="<image-name>"                      # your image name
export IMAGE_TAG="1"                                  # your image tag
export ENV="aca-env-sticky-sessions"                  # Container Apps environment name

# Example:
export CONTAINER_REGISTRY="ghcr.io/<NAMESPACE>"
export IMAGE_NAME="aca-affinity"
export IMAGE_TAG="1"
export ENV="aca-env-sticky-sessions"
```

### Deploy to Azure

1. **Make the script executable (if on Linux/macOS):**
   ```bash
   chmod +x deploy/azure-deploy.sh
   ```

2. **Run the deployment script:**
   ```bash
   ./deploy/azure-deploy.sh
   ```

The script will:
- Create a resource group named `rg-aca-sticky-sessions`
- Create a Container Apps environment
- Deploy your application with external HTTP ingress
- Configure session affinity (sticky sessions)
- Scale to 2 replicas for testing
- Test the deployment with curl commands

### Testing the Azure Deployment

After deployment, the script automatically tests the application. You can also test manually:

```bash
# Get the application FQDN
APP_FQDN=$(az containerapp show --name aca-sticky-sessions-demo --resource-group rg-aca-sticky-sessions --query properties.configuration.ingress.fqdn -o tsv)

# Test with session affinity
curl -i -c cookies.txt -b cookies.txt https://$APP_FQDN/whoami
curl -i -c cookies.txt -b cookies.txt https://$APP_FQDN/whoami
curl -i -c cookies.txt -b cookies.txt https://$APP_FQDN/whoami
```

### Managing Session Affinity

To toggle session affinity after deployment:

**Enable sticky sessions:**
```bash
az containerapp ingress sticky-sessions set \
  --name aca-sticky-sessions-demo \
  --resource-group rg-aca-sticky-sessions \
  --affinity 'sticky'
```

**Disable sticky sessions:**
```bash
az containerapp ingress sticky-sessions set \
  --name aca-sticky-sessions-demo \
  --resource-group rg-aca-sticky-sessions \
  --affinity 'none'
```

**Check current affinity setting:**
```bash
az containerapp ingress sticky-sessions show \
  --name aca-sticky-sessions-demo \
  --resource-group rg-aca-sticky-sessions
```

### Cleanup

To remove all Azure resources:

```bash
az group delete --name rg-aca-sticky-sessions --yes --no-wait
```