# Azure Red Hat OpenShift (ARO) Cluster Deployment with Managed Identity

This repository contains Bicep templates and deployment scripts for creating an Azure Red Hat OpenShift cluster using managed identities.

## Source Material

This implementation is based on the official Microsoft documentation:
- [Create an Azure Red Hat OpenShift cluster using Bicep](https://learn.microsoft.com/en-us/azure/openshift/howto-create-openshift-cluster?pivots=aro-deploy-az-bicep#example-bicep-file)

## Prerequisites

Before running the deployment, ensure you have:

1. **Azure CLI** installed and configured
2. **Azure subscription** with appropriate permissions
3. **Red Hat pull secret** from [cloud.redhat.com](https://cloud.redhat.com/openshift/install/azure/aro-provisioned)
4. **Resource group** created in Azure
5. **Azure Red Hat OpenShift Resource Provider** registered in your subscription

## Setup

1. **Get your Red Hat pull secret:**
   - Visit https://cloud.redhat.com/openshift/install/azure/aro-provisioned
   - Download your pull secret and save it as `pull-secret.txt` in this directory

2. **Update the deployment parameters:**
   - Edit the `run.sh` file and replace the placeholder values:
     - `LOCATION`: Your Azure region (e.g., `australiaeast`)
     - `RESOURCEGROUP`: Your resource group name
     - `CLUSTER`: Your desired cluster name
     - `VERSION`: OpenShift version (e.g., `4.18.26`)
     - `DOMAIN`: A unique domain prefix for your cluster

## How to Execute

1. **Make the script executable** (if on Linux/macOS):
   ```bash
   chmod +x run.sh
   ```

2. **Run the deployment script:**
   ```bash
   ./run.sh
   ```

3. **Monitor the deployment:**
   - The deployment will take approximately 30-40 minutes
   - You can monitor progress in the Azure Portal or via Azure CLI:
     ```bash
     az deployment group show --name aroDeployment --resource-group <your-resource-group>
     ```

## What Gets Deployed

This deployment creates:
- Virtual network with master and worker subnets
- Multiple managed identities for cluster components
- Role assignments for managed identities
- Azure Red Hat OpenShift cluster with:
  - 3 master nodes
  - 3 worker nodes
  - Network and security configurations

## Security Notes

- **Never commit `pull-secret.txt`** to version control (it's in `.gitignore`)
- All sensitive parameters are passed at deployment time
- Managed identities are used for secure authentication
- The Bicep template uses `@secure()` decorator for sensitive inputs

## Cleanup

To delete the cluster and associated resources:

```bash
az group delete --name <your-resource-group> --yes --no-wait
```

## Additional Resources

- [Azure Red Hat OpenShift Documentation](https://learn.microsoft.com/en-us/azure/openshift/)
- [OpenShift Documentation](https://docs.openshift.com/)
- [Red Hat Customer Portal](https://access.redhat.com/)
