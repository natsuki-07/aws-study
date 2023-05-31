#!/bin/bash
set -euo pipefail

# 変数
PREFIX="sample01"
## ドメインは別途用意したもの
MY_DOMAIN="sample01.20230331"
PUBLIC_SUBNET_1a_ID=$(aws ec2 describe-subnets --filters Name=tag:Name,Values=${PREFIX}-public-subnet-1a --query "Subnets[*].SubnetId" --output text) && echo $PUBLIC_SUBNET_1a_ID
PUBLIC_SUBNET_1c_ID=$(aws ec2 describe-subnets --filters Name=tag:Name,Values=${PREFIX}-public-subnet-1c --query "Subnets[*].SubnetId" --output text) && echo $PUBLIC_SUBNET_1c_ID
ELB_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters Name=tag:Name,Values=${PREFIX}-elb-sg --query "SecurityGroups[*].GroupId" --output text) && echo $ELB_SECURITY_GROUP_ID
VPC_ID=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=${PREFIX}-vpc --query "Vpcs[*].VpcId" --output text) && echo $VPC_ID
CERTIFICATE_ARN=$(aws acm list-certificates --query "CertificateSummaryList[?DomainName==\`*.$MY_DOMAIN\`].CertificateArn" --output text) && echo $CERTIFICATE_ARN

# ELB
LOAD_BALANCER_ARN=$(aws elbv2 create-load-balancer \
--name ${PREFIX}-alb \
--subnets $PUBLIC_SUBNET_1a_ID $PUBLIC_SUBNET_1c_ID \
--security-groups $ELB_SECURITY_GROUP_ID\
--scheme internet-facing\
--type application\
--query "LoadBalancers[*].LoadBalancerArn"\
--output text) && echo $LOAD_BALANCER_ARN

# TargetGroup
## ヘルスチェックはコンソールのデフォルト値
TARGET_GROUP_ARN=$(aws elbv2 create-target-group \
  --name ${PREFIX}-alb-tg \
  --target-type ip \
  --protocol HTTP \
  --port 80 \
  --protocol-version HTTP1 \
  --vpc-id $VPC_ID \
  --health-check-protocol HTTP \
  --health-check-path / \
  --health-check-port traffic-port \
  --healthy-threshold-count 5 \
  --unhealthy-threshold-count 2 \
  --health-check-timeout-seconds 5 \
  --health-check-interval-seconds 30 \
  --matcher HttpCode=200 \
  --query "TargetGroups[*].TargetGroupArn" --output text) && echo $TARGET_GROUP_ARN

# Regster targets
## EC2のIPアドレス
aws elbv2 register-targets \
  --target-group-arn $TARGET_GROUP_ARN \
  --targets Id=10.0.11.11 Id=10.0.12.11

## Listener
# HTTP
## #{host}←デフォルト
aws elbv2 create-listener \
  --load-balancer-arn $LOAD_BALANCER_ARN \
  --protocol HTTP \
  --port 80  \
  --default-actions 'Type=redirect,RedirectConfig={Protocol=HTTPS,Port=443,Host="#{host}",Path="/#{path}",Query="#{query}",StatusCode=HTTP_301}'

# HTTPS
aws elbv2 create-listener \
  --load-balancer-arn $LOAD_BALANCER_ARN \
  --protocol HTTPS \
  --port 443  \
  --certificates CertificateArn=$CERTIFICATE_ARN \
  --default-actions Type=forward,TargetGroupArn=$TARGET_GROUP_ARN


## ELB alias
MY_DOMAIN="sample01.20230331"
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones --query "HostedZones[?Name==\`${MY_DOMAIN}.\`].Id" --output text) && echo $HOSTED_ZONE_ID

PREFIX="sample01"
ELB_NAME="${PREFIX}-alb"
FQDN="www.${MY_DOMAIN}"
ELB_HOSTED_ZONE_ID=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?LoadBalancerName==\`$ELB_NAME\`].CanonicalHostedZoneId" --output text) && echo $ELB_HOSTED_ZONE_ID
ELB_DNS_NAME=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?LoadBalancerName==\`$ELB_NAME\`].DNSName" --output text) && echo $ELB_DNS_NAME

# Update record sets file
ELB_RECORD_FILE=./elb.json
sed -i -e "s/%FQDN%/$FQDN/" $ELB_RECORD_FILE
sed -i -e "s/%ELB_HOSTED_ZONE_ID%/$ELB_HOSTED_ZONE_ID/" $ELB_RECORD_FILE
sed -i -e "s/%ELB_DNS_NAME%/$ELB_DNS_NAME/" $ELB_RECORD_FILE

# Add record sets
aws route53 change-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --change-batch file://$ELB_RECORD_FILE
  
# Initialize
git restore $ELB_RECORD_FILE
