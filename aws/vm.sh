#!/bin/bash


# Parameters
REGION="ap-south-1"
AMI_ID="ami-0d5d9d301c853a04a"   
INSTANCE_TYPE="t2.micro"
KEY_NAME="my-ec2-key"
SECURITY_GROUP="my-ec2-sg"
TAG_NAME="MyEC2Instance"


if [ ! -f "$HOME/.ssh/${KEY_NAME}.pem" ]; then
    echo "[+] Creating a new SSH key..."
    aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > "$HOME/.ssh/${KEY_NAME}.pem"
    chmod 400 "$HOME/.ssh/${KEY_NAME}.pem"
fi

# Create Security Group if not exists
SG_ID=$(aws ec2 describe-security-groups --group-names "$SECURITY_GROUP" --region $REGION --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null)
if [ "$SG_ID" == "None" ]; then
    echo "[+] Creating security group $SECURITY_GROUP..."
    SG_ID=$(aws ec2 create-security-group --group-name $SECURITY_GROUP --description "Security group for $TAG_NAME" --region $REGION --query 'GroupId' --output text)
    
    # Add SSH and HTTP rules
    aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
    aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0
fi

# Launch EC2 instance
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$TAG_NAME}]" \
    --query 'Instances[0].InstanceId' \
    --output text \
    --region $REGION
)

echo "[+] Waiting for instance $INSTANCE_ID to be running..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION

# Fetch Public IP
PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text --region $REGION)

# Display Summary
echo "===================================="
echo " VM Created Successfully!"
echo " Instance ID   : $INSTANCE_ID"
echo " Region        : $REGION"
echo " Public IP     : $PUBLIC_IP"
echo " SSH Command   : ssh -i ~/.ssh/${KEY_NAME}.pem ubuntu@$PUBLIC_IP"
echo " HTTP URL      : http://$PUBLIC_IP"
echo "===================================="
