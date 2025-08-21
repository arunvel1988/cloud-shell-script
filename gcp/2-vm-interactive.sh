#!/bin/bash



# Ask project ID only
read -p "Enter your GCP Project ID: " PROJECT_ID

# Fixed service account
SERVICE_ACCOUNT="terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com"

# Ask zone
echo "[*] Listing available zones (showing top 10)..."
gcloud compute zones list --project=$PROJECT_ID | awk '{print $1,$2,$3}' | head -10
read -p "Enter the Zone (e.g., asia-south1-a): " ZONE

# Ask VM name
read -p "Enter VM Name: " VM_NAME

# Ask machine type
echo "[*] Some common machine types: e2-micro, e2-small, e2-medium, n1-standard-1"
read -p "Enter Machine Type: " MACHINE_TYPE

# Ask boot disk size
read -p "Enter Boot Disk Size (e.g., 10GB): " BOOT_DISK_SIZE

# Ask boot disk type
echo "[*] Options: pd-standard, pd-balanced, pd-ssd"
read -p "Enter Boot Disk Type: " BOOT_DISK_TYPE

# Ask image family
echo "[*] Examples: ubuntu-2204-lts, debian-11, centos-7"
read -p "Enter Image Family: " IMAGE_FAMILY

# Ask image project
echo "[*] Common options: ubuntu-os-cloud, debian-cloud, centos-cloud"
read -p "Enter Image Project: " IMAGE_PROJECT

# Firewall tags
FIREWALL_TAG_HTTP="http-server"
FIREWALL_TAG_HTTPS="https-server"
FIREWALL_TAG_SSH="ssh"
SOURCE_RANGE="0.0.0.0/0"

echo "[+] Authenticating service account..."
gcloud config set account $SERVICE_ACCOUNT

echo "[+] Setting project..."
gcloud config set project $PROJECT_ID

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

echo "[+] Creating firewall rule to allow SSH (if not exists)..."
gcloud compute firewall-rules create allow-ssh \
  --allow tcp:22 \
  --source-ranges=$SOURCE_RANGE \
  --target-tags=$FIREWALL_TAG_SSH \
  --project=$PROJECT_ID || echo "[!] Firewall rule already exists, skipping..."

echo "[+] Adding SSH tag to VM..."
gcloud compute instances add-tags $VM_NAME \
  --tags=$FIREWALL_TAG_SSH \
  --zone=$ZONE \
  --project=$PROJECT_ID

echo "[+] Connect to your VM via SSH..."
gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID

echo "[+] Script completed successfully!"
