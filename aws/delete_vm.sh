#!/bin/bash



# Parameters
REGION="ap-south-1"

# List all instances
echo "[+] Listing all EC2 instances in $REGION..."
aws ec2 describe-instances \
    --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0],State.Name]' \
    --output table \
    --region $REGION

# Get instance IDs into array
INSTANCE_IDS=($(aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceId' --output text --region $REGION))

if [ ${#INSTANCE_IDS[@]} -eq 0 ]; then
    echo "No EC2 instances found in region $REGION."
    exit 0
fi

# Ask user to select instance(s) to delete
echo "Select instances to delete by number:"
for i in "${!INSTANCE_IDS[@]}"; do
    NAME=$(aws ec2 describe-instances --instance-ids "${INSTANCE_IDS[$i]}" --query 'Reservations[0].Instances[0].Tags[?Key==`Name`].Value' --output text --region $REGION)
    STATE=$(aws ec2 describe-instances --instance-ids "${INSTANCE_IDS[$i]}" --query 'Reservations[0].Instances[0].State.Name' --output text --region $REGION)
    echo "$((i+1)). $NAME ($STATE) [${INSTANCE_IDS[$i]}]"
done

read -p "Enter the number(s) of instance(s) to delete (space separated): " -a SELECTIONS

# Confirm and delete
for index in "${SELECTIONS[@]}"; do
    INSTANCE_ID="${INSTANCE_IDS[$((index-1))]}"
    read -p "Are you sure you want to delete instance '$INSTANCE_ID'? [y/N]: " CONFIRM
    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
        echo "[+] Deleting instance $INSTANCE_ID..."
        aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region $REGION
    else
        echo "Skipping $INSTANCE_ID"
    fi
done

echo "[+] Deletion script completed."
