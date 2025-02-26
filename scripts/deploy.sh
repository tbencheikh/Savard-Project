#!/bin/bash
echo "Deploying infrastructure..."
terraform init
terraform apply -auto-approve

echo "Configuring server with Ansible..."
ansible-playbook ansible/playbooks/ad-config.yml