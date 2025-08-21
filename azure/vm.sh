#!/bin/bash

RESOURCE_GROUP="myResourceGroup"
VM_NAME="myVM"
LOCATION="centralindia"  
IMAGE="Ubuntu2404"        
SIZE="Standard_B1s"       
ADMIN_USER="azureuser"
SSH_KEY="$HOME/.ssh/id_rsa.pub"

# Generate SSH key if not exists
if [ ! -f "$SSH_KEY" ]; then
    echo "SSH key not found, generating one..."
    ssh-keygen -t rsa -b 2048 -f "$HOME/.ssh/id_rsa" -N ""
fi

# Create Resource Group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create a network security group
az network nsg create \
  --resource-group $RESOURCE_GROUP \
  --name "${VM_NAME}-nsg"

# Add rules for SSH (22) and HTTP (80)
az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name "${VM_NAME}-nsg" \
  --name "Allow-SSH" \
  --protocol tcp \
  --priority 1000 \
  --destination-port-ranges 22 \
  --access Allow \
  --direction Inbound

az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name "${VM_NAME}-nsg" \
  --name "Allow-HTTP" \
  --protocol tcp \
  --priority 1001 \
  --destination-port-ranges 80 \
  --access Allow \
  --direction Inbound

# Create virtual network and subnet
az network vnet create \
  --resource-group $RESOURCE_GROUP \
  --name "${VM_NAME}-vnet" \
  --subnet-name "${VM_NAME}-subnet"

# Create public IP
az network public-ip create \
  --resource-group $RESOURCE_GROUP \
  --name "${VM_NAME}-pip" \
  --allocation-method Static

# Create NIC attached to NSG and public IP
az network nic create \
  --resource-group $RESOURCE_GROUP \
  --name "${VM_NAME}-nic" \
  --vnet-name "${VM_NAME}-vnet" \
  --subnet "${VM_NAME}-subnet" \
  --network-security-group "${VM_NAME}-nsg" \
  --public-ip-address "${VM_NAME}-pip"

# Create the VM
az vm create \
  --resource-group $RESOURCE_GROUP \
  --name $VM_NAME \
  --nics "${VM_NAME}-nic" \
  --image $IMAGE \
  --size $SIZE \
  --admin-username $ADMIN_USER \
  --ssh-key-values $SSH_KEY \
  --no-wait

# Fetch public IP
PUBLIC_IP=$(az vm show \
  --resource-group $RESOURCE_GROUP \
  --name $VM_NAME \
  --show-details \
  --query publicIps \
  -o tsv)

# Display summary
echo "[+] VM Created Successfully!"
echo "===================================="
echo " VM Name       : $VM_NAME"
echo " Resource Group: $RESOURCE_GROUP"
echo " Location      : $LOCATION"
echo " Public IP     : $PUBLIC_IP"
echo " SSH Command   : ssh $ADMIN_USER@$PUBLIC_IP"
echo " HTTP URL      : http://$PUBLIC_IP"
echo "===================================="
