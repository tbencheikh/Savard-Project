#!/bin/bash

# Variables
RESOURCE_GROUP="savard-rg"
SUBSCRIPTION_ID=$ARM_SUBSCRIPTION_ID
LOG_FILE="./import_log.txt"

# Créer ou réinitialiser le fichier de log
> $LOG_FILE

# Fonction pour importer une ressource
import_resource() {
  RESOURCE_TYPE=$1
  RESOURCE_NAME=$2
  AZURE_ID=$3

  echo "Vérification de l'existence de la ressource $RESOURCE_NAME de type $RESOURCE_TYPE..." | tee -a $LOG_FILE
  if az resource show --ids "$AZURE_ID" &> /dev/null; then
    echo "La ressource existe. Importation dans Terraform..." | tee -a $LOG_FILE
    terraform import "$RESOURCE_TYPE.$RESOURCE_NAME" "$AZURE_ID" | tee -a $LOG_FILE
    if [ $? -ne 0 ]; then
      echo "❌ Erreur lors de l'importation de la ressource $RESOURCE_NAME." | tee -a $LOG_FILE
      exit 1
    fi
  else
    echo "La ressource n'existe pas. Aucune action nécessaire." | tee -a $LOG_FILE
  fi
}

# Liste des ressources à importer
RESOURCES=(
  "azurerm_resource_group rg /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"
  "azurerm_virtual_network vnet /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/virtualNetworks/savard-vnet"
  "azurerm_subnet subnet /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/virtualNetworks/savard-vnet/subnets/savard-subnet"
  "azurerm_public_ip public_ip /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/publicIPAddresses/savard-public-ip"
  "azurerm_network_security_group winrm_nsg /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/networkSecurityGroups/winrm-nsg"
  "azurerm_network_interface nic /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/networkInterfaces/savard-nic"
  "azurerm_windows_virtual_machine server /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Compute/virtualMachines/savard-server"
  "azurerm_virtual_machine_extension winrm_extension /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Compute/virtualMachines/savard-server/extensions/winrm-config"
  "azurerm_network_interface_security_group_association nic_nsg_assoc /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/networkInterfaces/savard-nic|/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/networkSecurityGroups/winrm-nsg"
)

# Importer toutes les ressources
for RESOURCE in "${RESOURCES[@]}"; do
  RESOURCE_TYPE=$(echo "$RESOURCE" | awk '{print $1}')
  RESOURCE_NAME=$(echo "$RESOURCE" | awk '{print $2}')
  AZURE_ID=$(echo "$RESOURCE" | awk '{print $3}')
  import_resource "$RESOURCE_TYPE" "$RESOURCE_NAME" "$AZURE_ID"
done
