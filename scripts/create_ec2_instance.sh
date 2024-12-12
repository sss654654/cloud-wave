#!/bin/bash

# VPC / SUBNETS INFORMATION
VPC_NAME="lab-edu-vpc-ap-01"
PRI_SUB_NAME_01="lab-edu-sub-pri-01"
PRI_SUB_NAME_02="lab-edu-sub-pri-02"
NETWORK_EC2_NAME_01="lab-edu-ec2-network-ap-01"
NETWORK_EC2_NAME_02="lab-edu-ec2-network-ap-02"

# GET VPC ID
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$VPC_NAME" --query "Vpcs[].VpcId" --output text)
if [ -z "$VPC_ID" ]; then
  echo "Error: VPC not found."
  exit 1
else
  echo "VPC found: $VPC_ID"
fi

# GET SUBNET ID
SUBNET_ID_PRIVATE_01=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=$PRI_SUB_NAME_01" --query "Subnets[].SubnetId" --output text)
SUBNET_ID_PRIVATE_02=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=$PRI_SUB_NAME_02" --query "Subnets[].SubnetId" --output text)
if [ -z "$SUBNET_ID_PRIVATE_01" ] || [ -z "$SUBNET_ID_PRIVATE_02" ]; then
  echo "Error: One or both subnets not found."
  exit 1
else
  echo "PRIVATE_SUBNET_01 found: $SUBNET_ID_PRIVATE_01"
  echo "PRIVATE_SUBNET_02 found: $SUBNET_ID_PRIVATE_02"
fi

# INSTANCE INFORMATION
AMI_ID="ami-0ff1cd0b5d98708d1"
INSTANCE_TYPE="t3.micro"

# CREATE KEY-PAIR
KEY_NAME="lab-edu-key-network"
KEY_PATH="/home/ec2-user/.ssh/$KEY_NAME.pem"
aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > $KEY_NAME.pem
if [ $? -eq 0 ]; then
  chmod 400 $KEY_NAME.pem
  yes | mv $KEY_NAME.pem $KEY_PATH
  echo "Key pair created successfully: $KEY_PATH"
else
  echo "Failed to create key pair: $KEY_NAME"
  exit 1
fi

# CREATE SECURITY-GROUP
SG_NAME="lab-edu-sg-network"
SG_ID=$(aws ec2 create-security-group --group-name $SG_NAME --description "My security group" --vpc-id $VPC_ID --output text)
if [ -z "$SG_ID" ]; then
  echo "Failed to create Security Group: $SG_ID"
  exit 1
else
  echo "VPC found: $SG_ID"
fi

# Allow ICMP & SSH access
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr 10.0.0.0/8 > /dev/null
if [ $? -eq 0 ]; then
  echo "Security Group Rule created successfully: SSH"
else
  echo "Failed to create Security Group Rule: SSH"
  exit 1
fi
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol icmp --port -1 --cidr 10.0.0.0/8 > /dev/null
if [ $? -eq 0 ]; then
  echo "Security Group Rule created successfully: ICMP"
else
  echo "Failed to create Security Group Rule: ICMP"
  exit 1
fi


# CREATE INSTANCES
NETWORK_EC2_IP_01=$(aws ec2 run-instances --image-id $AMI_ID --count 1 --instance-type $INSTANCE_TYPE --key-name $KEY_NAME --security-group-ids $SG_ID --subnet-id $SUBNET_ID_PRIVATE_01 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$NETWORK_EC2_NAME_01}]" --query "Instances[0].PrivateIpAddress" --output text)
INSTANCE_ID_01=$(aws ec2 describe-instances --filters "Name=private-ip-address,Values=$NETWORK_EC2_IP_01" --query "Reservations[].Instances[].InstanceId" --output text)
NETWORK_EC2_IP_02=$(aws ec2 run-instances --image-id $AMI_ID --count 1 --instance-type $INSTANCE_TYPE --key-name $KEY_NAME --security-group-ids $SG_ID --subnet-id $SUBNET_ID_PRIVATE_02 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$NETWORK_EC2_NAME_02}]" --query "Instances[0].PrivateIpAddress" --output text)
INSTANCE_ID_02=$(aws ec2 describe-instances --filters "Name=private-ip-address,Values=$NETWORK_EC2_IP_02" --query "Reservations[].Instances[].InstanceId" --output text)
if [ -z "$NETWORK_EC2_IP_01" ] || [ -z "$NETWORK_EC2_IP_02" ]; then
  echo "Error: One or both instance not found."
  exit 1
else
  echo "NETWORK_EC2_01 created successfully: $NETWORK_EC2_IP_01, $INSTANCE_ID_01"
  echo "NETWORK_EC2_02 created successfully: $NETWORK_EC2_IP_02, $INSTANCE_ID_02"
fi

# IAM Role Binding
IAM_ROLE_NAME="lab-edu-role-ec2"
aws ec2 associate-iam-instance-profile --instance-id $INSTANCE_ID_01 --iam-instance-profile Name=$IAM_ROLE_NAME
aws ec2 associate-iam-instance-profile --instance-id $INSTANCE_ID_02 --iam-instance-profile Name=$IAM_ROLE_NAME

CONFIG_PATH="/home/ec2-user/.ssh/config"
cat <<EOF >> $CONFIG_PATH

Host network-01
  HostName $NETWORK_EC2_IP_01
  User ec2-user
  IdentityFile $KEY_PATH

Host network-02
  HostName $NETWORK_EC2_IP_02
  User ec2-user
  IdentityFile $KEY_PATH
EOF
if [ $? -eq 0 ]; then
  echo "Configuration created successfully: $CONFIG_PATH"
else
  echo "Failed to create Configuration: $CONFIG_PATH"
  exit 1
fi
