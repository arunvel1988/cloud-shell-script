#!/bin/bash

RESOURCE_GROUP="myResourceGroup"

# List all VMs in the resource group
VM_LIST=($(az vm list --resource-group $RESOURCE_GROUP --query "[].name" -o tsv))

if [ ${#VM_LIST[@]} -eq 0 ]; then
    echo "No VMs found in resource group '$RESOURCE_GROUP'."
    exit 0
fi

echo "List of VMs in resource group '$RESOURCE_GROUP':"
for i in "${!VM_LIST[@]}"; do
    echo "$((i+1)). ${VM_LIST[$i]}"
done

# Ask user to select VM
read -p "Enter the number of the VM you want to delete: " VM_NUMBER

# Validate input
if ! [[ "$VM_NUMBER" =~ ^[0-9]+$ ]] || [ "$VM_NUMBER" -lt 1 ] || [ "$VM_NUMBER" -gt ${#VM_LIST[@]} ]; then
    echo "Invalid selection."
    exit 1
fi

SELECTED_VM=${VM_LIST[$((VM_NUMBER-1))]}

# Confirm before deletion
read -p "Are you sure you want to delete VM '$SELECTED_VM'? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Deletion cancelled."
    exit 0
fi

# Delete the VM
az vm delete --resource-group $RESOURCE_GROUP --name "$SELECTED_VM" --yes

echo "VM '$SELECTED_VM' has been deleted successfully."
