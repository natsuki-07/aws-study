#!/bin/bash
set -euo pipefail

# Variables
PREFIX="sample01"
## 最新AMIの取得
AMI_ID=$(aws ssm get-parameters --names /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 --query "Parameters[*].Value" --output text) && echo $AMI_ID
PUBLIC_SUBNET_ID=$(aws ec2 describe-subnets --filters Name=tag:Name,Values=${PREFIX}-public-subnet-1a --query "Subnets[*].SubnetId" --output text) && echo $PUBLIC_SUBNET_ID
EC2_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters Name=tag:Name,Values=${PREFIX}-ec2-sg --query "SecurityGroups[*].GroupId" --output text) && echo $EC2_SECURITY_GROUP_ID
EC2_NAME="${PREFIX}-web-01"
PRIVATE_IP_ADDRESS="10.0.11.11"
# AMIが複数ある場合は&CreationDateをキーに並び替えをして[-1]により最新のものを取得できる
# AMI_ID=$(aws ec2 describe-images --owner self --filters Name=tag:Name,Values=${PREFIX}-web-01_* --query "sort_by(Images, &CreationDate)[-1].ImageId" --output text) && echo $AMI_ID

# EC2
## コンソールでのデフォルト値
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t2.micro \
  --count 1 \
  --subnet-id $PUBLIC_SUBNET_ID \
  --associate-public-ip-address \
  --iam-instance-profile Name=${PREFIX}-ec2-role \
  --enable-api-termination \
  --monitoring Enabled=false \
  --private-ip-address $PRIVATE_IP_ADDRESS \
  --user-data file://userdata.sh \
  --block-device-mappings file://volume.json \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$EC2_NAME}]" \
  --security-group-ids $EC2_SECURITY_GROUP_ID \
  --key-name ${PREFIX}-key \
  --query "Instances[*].InstanceId" \
  --output text) && echo $INSTANCE_ID

# Tag
## ネットワークインターフェイスとボリュームにはcliから作成したときにタグが付かない
NETWORK_INTERFACE_ID=$(aws ec2 describe-instances \
  --instance-id $INSTANCE_ID \
  --query "Reservations[*].Instances[*].NetworkInterfaces[*].NetworkInterfaceId" \
  --output text) && echo $NETWORK_INTERFACE_ID

VOLUME_IDS=$(aws ec2 describe-instances \
  --instance-id $INSTANCE_ID \
  --query "Reservations[*].Instances[*].BlockDeviceMappings[*].Ebs.VolumeId" \
  --output text) && echo $VOLUME_IDS

aws ec2 create-tags --resources $NETWORK_INTERFACE_ID $VOLUME_IDS --tags Key=Name,Value=$EC2_NAME

# 動作確認
PUBLIC_IP_ADDRESS=$(aws ec2 describe-instances --instance-id $INSTANCE_ID --query "Reservations[*].Instances[*].PublicIpAddress" --output text) && echo $PUBLIC_IP_ADDRESS
curl http://$PUBLIC_IP_ADDRESS

