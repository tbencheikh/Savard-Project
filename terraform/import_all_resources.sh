#!/bin/bash

# Définition des variables
RESOURCE_GROUP="savard-rg"
SUBSCRIPTION_ID=$ARM_SUBSCRIPTION_ID
LOG_FILE="./import_log.txt"

# Création ou réinitialisation du fichier de log
> $LOG_FILE

# Fonction pour importer une ressource dans Terraform
import_resource() {
  RESOURCE_TYPE=$1
  RESOURCE_NAME=$2
  AZURE_ID=$3

  echo "🔍 Vérification de la ressource $RESOURCE_NAME ($RESOURCE_TYPE)..." | tee -a $LOG_FILE
  
  # Vérifier si la ressource existe sur Azure
  if az resource show --ids "$AZURE_ID" &> /dev/null; then
    echo "✅ Ressource trouvée ! Importation dans Terraform..." | tee -a $LOG_FILE
    terraform import "$RESOURCE_TYPE.$RESOURCE_NAME" "$AZURE_ID" | tee -a $LOG_FILE
    
    # Vérification de l'importation
    if [ $? -ne 0 ]; then
      echo "❌ Erreur : échec de l'importation de $RESOURCE_NAME !" | tee -a $LOG_FILE
      exit 1
    fi
  else
    echo "⚠️ Ressource $RESOURCE_NAME introuvable. Aucune action effectuée." | tee -a $LOG_FILE
  fi
}

# Liste des ressources à importer avec leurs IDs Azure corrects
RESOURCES=(
  "azurerm_resource_group rg /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"
  "azurerm_virtual_network vnet /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/virtualNetworks/savard-vnet"
  "azurerm_subnet subnet /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/virtualNetworks/savard-vnet/subnets/savard-subnet"
  "azurerm_public_ip public_ip /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/publicIPAddresses/savard-public-ip"
  "azurerm_network_security_group winrm_nsg /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/networkSecurityGroups/winrm-nsg"
  "azurerm_network_interface nic /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/networkInterfaces/savard-nic"
  "azurerm_windows_virtual_machine savard-server /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Compute/virtualMachines/savard-server"
  "azurerm_virtual_machine_extension winrm_setup /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Compute/virtualMachines/savard-server/extensions/winrm-config"
)

# 🔄 Importation des ressources
for RESOURCE in "${RESOURCES[@]}"; do
  RESOURCE_TYPE=$(echo "$RESOURCE" | awk '{print $1}')
  RESOURCE_NAME=$(echo "$RESOURCE" | awk '{print $2}')
  AZURE_ID=$(echo "$RESOURCE" | awk '{print $3}')
  
  import_resource "$RESOURCE_TYPE" "$RESOURCE_NAME" "$AZURE_ID"
done

# 🔧 Gestion spécifique de azurerm_network_interface_security_group_association
NIC_ID="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/networkInterfaces/savard-nic"
NSG_ID="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/networkSecurityGroups/winrm-nsg"

echo "🔍 Vérification de l'association entre l'interface réseau et le groupe de sécurité..." | tee -a $LOG_FILE

if az network nic show --ids "$NIC_ID" &> /dev/null && az network nsg show --ids "$NSG_ID" &> /dev/null; then
  echo "✅ Association trouvée ! Importation dans Terraform..." | tee -a $LOG_FILE
  terraform import azurerm_network_interface_security_group_association.nic_nsg_assoc "$NIC_ID/$NSG_ID" | tee -a $LOG_FILE
  
  if [ $? -ne 0 ]; then
    echo "❌ Erreur : impossible d'importer l'association entre NIC et NSG !" | tee -a $LOG_FILE
    exit 1
  fi
else
  echo "⚠️ Association introuvable. Aucune action effectuée." | tee -a $LOG_FILE
fi

echo "🎉 Importation terminée avec succès !" | tee -a $LOG_FILE
