#!/bin/bash

# Variables
RESOURCE_GROUP="savard-rg"
SUBSCRIPTION_ID=$ARM_SUBSCRIPTION_ID
LOG_FILE="./import_log.txt"

# Créer ou réinitialiser le fichier de log
> $LOG_FILE

# Vérification des variables obligatoires
if [[ -z "$SUBSCRIPTION_ID" ]]; then
  echo "❌ ERREUR : L'ID de l'abonnement Azure (SUBSCRIPTION_ID) est vide !" | tee -a $LOG_FILE
  exit 1
fi

# Fonction pour importer une ressource
import_resource() {
  RESOURCE_TYPE=$1
  RESOURCE_NAME=$2
  AZURE_ID=$3

  echo "🔍 Vérification de la ressource $RESOURCE_NAME ($RESOURCE_TYPE)..." | tee -a $LOG_FILE

  # Vérifie si Terraform gère déjà cette ressource
  if terraform state list | grep -q "$RESOURCE_TYPE.$RESOURCE_NAME"; then
    echo "✅ La ressource $RESOURCE_NAME est déjà gérée par Terraform." | tee -a $LOG_FILE
    return
  fi

  # Vérifie si la ressource existe dans Azure
  if az resource show --ids "$AZURE_ID" &> /dev/null; then
    echo "📥 Importation de $RESOURCE_NAME dans Terraform..." | tee -a $LOG_FILE
    terraform import "$RESOURCE_TYPE.$RESOURCE_NAME" "$AZURE_ID" | tee -a $LOG_FILE
    if [ $? -ne 0 ]; then
      echo "❌ ERREUR : L'importation de $RESOURCE_NAME ($RESOURCE_TYPE) a échoué !" | tee -a $LOG_FILE
      exit 1
    fi

    # Vérifier que la ressource est bien dans Terraform après l'importation
    terraform state list | grep "$RESOURCE_TYPE.$RESOURCE_NAME"
    if [ $? -ne 0 ]; then
      echo "❌ ERREUR : La ressource $RESOURCE_NAME ($RESOURCE_TYPE) n'est pas présente dans l'état Terraform après import !" | tee -a $LOG_FILE
      exit 1
    fi

  else
    echo "⚠️ La ressource $RESOURCE_NAME n'existe pas sur Azure, importation ignorée." | tee -a $LOG_FILE
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
  "azurerm_windows_virtual_machine savard-server /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Compute/virtualMachines/savard-server"
  "azurerm_virtual_machine_extension winrm_setup /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Compute/virtualMachines/savard-server/extensions/winrm-config"
)

# Importer toutes les ressources
for RESOURCE in "${RESOURCES[@]}"; do
  RESOURCE_TYPE=$(echo "$RESOURCE" | awk '{print $1}')
  RESOURCE_NAME=$(echo "$RESOURCE" | awk '{print $2}')
  AZURE_ID=$(echo "$RESOURCE" | awk '{print $3}')
  import_resource "$RESOURCE_TYPE" "$RESOURCE_NAME" "$AZURE_ID"
done

# Forcer une mise à jour de Terraform après l'importation
echo "🔄 Mise à jour de l'état Terraform..."
terraform refresh | tee -a $LOG_FILE

echo "✅ Importation terminée avec succès !" | tee -a $LOG_FILE
