#!/bin/bash


# Parameters
PROJECT_ID="arun-463003"
ZONE="asia-south1-a"  # default zone if user wants to specify
SERVICE_ACCOUNT="terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com"

# Authenticate and set project
echo "[+] Authenticating service account..."
gcloud auth list
gcloud config set account $SERVICE_ACCOUNT

echo "[+] Setting GCP project..."
gcloud config set project $PROJECT_ID

# List all VMs in project
echo "[+] Listing all VMs in project $PROJECT_ID..."
gcloud compute instances list --project $PROJECT_ID

# Fetch VM names into an array
VM_NAMES=($(gcloud compute instances list --project $PROJECT_ID --format="value(name)"))

if [ ${#VM_NAMES[@]} -eq 0 ]; then
    echo "No VMs found in project $PROJECT_ID."
    exit 0
fi

echo "============================"
echo "Available VMs:"
for i in "${!VM_NAMES[@]}"; do
    echo "$((i+1)). ${VM_NAMES[$i]}"
done
echo "============================"

# Ask user to select VM(s) to delete
read -p "Enter the number of the VM you want to delete (or multiple numbers separated by space): " -a SELECTIONS

# Confirm deletion
for index in "${SELECTIONS[@]}"; do
    VM_NAME="${VM_NAMES[$((index-1))]}"
    read -p "Are you sure you want to delete VM '$VM_NAME'? [y/N]: " CONFIRM
    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
        echo "[+] Deleting VM: $VM_NAME ..."
        gcloud compute instances delete "$VM_NAME" --zone=$ZONE --project=$PROJECT_ID --quiet
    else
        echo "Skipping VM: $VM_NAME"
    fi
done

echo "[+] Script completed."
