# 1. Define variables (adjust these as needed)
RG="rg-aca-tests"
LOCATION="australiaeast"
VNET_NAME="vnet-wldprofile"
ACA_SUBNET="subnet-aca"
BASTION_SUBNET="AzureBastionSubnet"
VM_SUBNET="subnet-vm"
CONTAINERAPPS_ENV="acaenv-vnetwldprofile"
CONTAINER_APP="acaapp-springboot"
LOG_ANALYTICS_WS="law-acavnetenv"
BASTION_PUBLIC_IP="pip-bastionwldprofile"
BASTION_RESOURCE="bastion-vnetwldprofile"
VM_NAME="vm-bastionwldprofile"
ADMIN_USERNAME="azureuser"
ADMIN_PASSWORD="<insert-password>"  # must meet Azure password policy

# 2. Create a resource group
az group create --name $RG --location $LOCATION

# 3. Create a VNet with the container apps subnet ("aca")
#    In this example, we use 10.140.0.0/16 for the VNet and a /27 for "aca"
az network vnet create \
  --resource-group $RG \
  --name $VNET_NAME \
  --address-prefixes 10.140.0.0/16 \
  --subnet-name $ACA_SUBNET \
  --subnet-prefix 10.140.0.0/27

# 4. Delegate the "aca" subnet to Azure Container Apps environments
az network vnet subnet update \
  --resource-group $RG \
  --vnet-name $VNET_NAME \
  --name $ACA_SUBNET \
  --delegations Microsoft.App/environments

# 5. Create the AzureBastionSubnet (must be named exactly that and use /27 or larger)
#    This subnet is required by the Bastion resource.
az network vnet subnet create \
  --resource-group $RG \
  --vnet-name $VNET_NAME \
  --name $BASTION_SUBNET \
  --address-prefix 10.140.0.32/27

# 6. Create an additional subnet for the Windows VM (bastion host)
az network vnet subnet create \
  --resource-group $RG \
  --vnet-name $VNET_NAME \
  --name $VM_SUBNET \
  --address-prefix 10.140.1.0/24

# 7. Create a Log Analytics workspace for Container Apps environment logging
az monitor log-analytics workspace create \
  --resource-group $RG \
  --workspace-name $LOG_ANALYTICS_WS \
  --location $LOCATION

# Retrieve the Log Analytics workspace resource ID and key (these are required for the environment)
WORKSPACE_ID=$(az monitor log-analytics workspace show \
  --resource-group $RG \
  --workspace-name $LOG_ANALYTICS_WS \
  --query id --output tsv)

WORKSPACE_KEY=$(az monitor log-analytics workspace get-shared-keys \
  --resource-group $RG \
  --workspace-name $LOG_ANALYTICS_WS \
  --query primarySharedKey --output tsv)

# 8. Create the Container Apps environment integrated with the VNet
az containerapp env create \
  --name $CONTAINERAPPS_ENV \
  --resource-group $RG \
  --location $LOCATION \
  --logs-workspace-id $WORKSPACE_ID \
  --logs-workspace-key $WORKSPACE_KEY \
  --vnet $VNET_NAME \
  --subnet $ACA_SUBNET

# 9. Create a container app within that environment.
#    Use internal ingress so it’s only accessible from within the VNet.
az containerapp create \
  --name $CONTAINER_APP \
  --resource-group $RG \
  --environment $CONTAINERAPPS_ENV \
  --image <container-image> \
  --ingress internal

# 10. Create a public IP for the Bastion host resource (must use SKU Standard)
az network public-ip create \
  --resource-group $RG \
  --name $BASTION_PUBLIC_IP \
  --sku Standard \
  --location $LOCATION

# 11. Create the Azure Bastion resource to enable secure RDP access into the VM.
az network bastion create \
  --resource-group $RG \
  --name $BASTION_RESOURCE \
  --vnet-name $VNET_NAME \
  --public-ip-address $BASTION_PUBLIC_IP \
  --location $LOCATION

# 12. Create the Windows 11 VM in the "vm-subnet"
#     Note: Replace the image reference with a valid Windows 11 image if available.
az vm create \
  --resource-group $RG \
  --name $VM_NAME \
  --image "MicrosoftWindowsDesktop:Windows-11:win11-21h2-pro:latest" \
  --admin-username $ADMIN_USERNAME \
  --admin-password $ADMIN_PASSWORD \
  --vnet-name $VNET_NAME \
  --subnet $VM_SUBNET \
  --no-wait
