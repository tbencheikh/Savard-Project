#!/bin/bash

# Récupérer l'adresse IP depuis la sortie de Terraform
IP=$(terraform output -raw server_private_ip)

# Générer le fichier hosts.yml
cat <<EOF > ./ansible/inventory/hosts.yml
all:
  hosts:
    savard-server:
      ansible_host: $IP
      ansible_user: adminuser
      ansible_password: "P@ssw0rd1234!"
      ansible_connection: winrm
      ansible_winrm_transport: basic
      ansible_winrm_server_cert_validation: ignore
EOF

echo "Fichier hosts.yml généré avec l'adresse IP : $IP"