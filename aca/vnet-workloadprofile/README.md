# Azure Container Apps with VNet and Workload Profiles

This project demonstrates how to deploy Azure Container Apps (ACA) with Virtual Network (VNet) integration and custom Workload Profiles using Infrastructure as Code (IaC).

## Project Structure

- `infra/azcli_commands.sh`: Shell script containing Azure CLI commands to provision resources.
- `LICENSE`: Project license information.

## Features

- Deploy ACA environment with VNet integration for secure networking.
- Configure custom Workload Profiles for optimized resource allocation.
- Automated deployment using Azure CLI.

## Prerequisites

- Azure CLI installed ([Install Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))
- An active Azure subscription
- Bash shell (for running scripts)

## Getting Started

1. **Clone the repository:**
   ```sh
   git clone <repo-url>
   cd aca-vnet-workloadprofile
   ```
2. **Login to Azure:**
   ```sh
   az login
   ```
3. **Run the deployment script:**
   ```sh
   cd infra
   bash azcli_commands.sh
   ```

## Customization

- Edit `infra/azcli_commands.sh` to modify resource names, locations, or workload profile settings as needed.

## Resources

- [Azure Container Apps Documentation](https://learn.microsoft.com/en-us/azure/container-apps/)
- [VNet Integration](https://learn.microsoft.com/en-us/azure/container-apps/networking)
- [Workload Profiles](https://learn.microsoft.com/en-us/azure/container-apps/workload-profiles)

## License

See `LICENSE` for details.
