#!/bin/bash

PROJECT_ID="arun-463003"
SERVICE_ACCOUNT="terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com"
ZONE="asia-south1-a"
VM_NAME="my-ubuntu-vm"
MACHINE_TYPE="e2-micro"
IMAGE_FAMILY="ubuntu-2204-lts"
IMAGE_PROJECT="ubuntu-os-cloud"
BOOT_DISK_SIZE="10GB"
BOOT_DISK_TYPE="pd-balanced"
FIREWALL_TAG_HTTP="http-server"
FIREWALL_TAG_HTTPS="https-server"
FIREWALL_TAG_SSH="ssh"
SOURCE_RANGE="0.0.0.0/0"

# Authenticate with GCP
echo "[+] Authenticating service account..."
gcloud auth list
gcloud config set account $SERVICE_ACCOUNT

# Set project
echo "[+] Setting GCP project..."
gcloud config set project $PROJECT_ID
gcloud projects describe $PROJECT_ID

# List useful info
echo "[+] Listing available regions..."
gcloud compute regions list
echo "[+] Listing all instances in project..."
gcloud compute instances list --project $PROJECT_ID


echo "[+] Creating VM: $VM_NAME ..."
gcloud compute instances create $VM_NAME \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --machine-type=$MACHINE_TYPE \
  --image-family=$IMAGE_FAMILY \
  --image-project=$IMAGE_PROJECT \
  --boot-disk-size=$BOOT_DISK_SIZE \
  --boot-disk-type=$BOOT_DISK_TYPE \
  --tags=$FIREWALL_TAG_HTTP,$FIREWALL_TAG_HTTPS


echo "[+] Creating firewall rule to allow SSH..."
gcloud compute firewall-rules create allow-ssh \
  --allow tcp:22,tcp:80 \
  --source-ranges=$SOURCE_RANGE \
  --target-tags=$FIREWALL_TAG_SSH \
  --project=$PROJECT_ID


echo "[+] Adding SSH tag to VM..."
gcloud compute instances add-tags $VM_NAME \
  --tags=$FIREWALL_TAG_SSH \
  --zone=$ZONE


echo "[+] Connect to your VM via SSH..."
gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID

echo "[+] Script completed successfully!"
