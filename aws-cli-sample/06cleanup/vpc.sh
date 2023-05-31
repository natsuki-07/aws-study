# 変数
PREFIX="sample01"
VPC_ID=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=${PREFIX}-vpc --query "Vpcs[*].VpcId" --output text)

# ルートテーブル
PUBLIC_ROUTE_TABLE_ID=$(aws ec2 describe-route-tables --filters Name=tag:Name,Values=${PREFIX}-public-route --query "RouteTables[*].RouteTableId" --output text) 
PRIVATE_ROUTE_TABLE_ID=$(aws ec2 describe-route-tables --filters Name=tag:Name,Values=${PREFIX}-privateroute --query "RouteTables[*].RouteTableId" --output text) 
PUBLIC_ROUTE_TABLE_ASSOCIATION_ID_1=$(aws ec2 describe-route-tables --filters Name=tag:Name,Values=${PREFIX}-public-route --query "RouteTables[*].Associations[0].RouteTableAssociationId" --output text) 
PUBLIC_ROUTE_TABLE_ASSOCIATION_ID_2=$(aws ec2 describe-route-tables --filters Name=tag:Name,Values=${PREFIX}-public-route --query "RouteTables[*].Associations[1].RouteTableAssociationId" --output text) 

## 関連付けをすべて解除してから削除
aws ec2 disassociate-route-table \
  --association-id $PUBLIC_ROUTE_TABLE_ASSOCIATION_ID_1

aws ec2 disassociate-route-table \
  --association-id $PUBLIC_ROUTE_TABLE_ASSOCIATION_ID_2

aws ec2 delete-route-table \
  --route-table-id $PUBLIC_ROUTE_TABLE_ID

# インターネットゲートウェイ
IGW_ID=$(aws ec2 describe-internet-gateways --filters Name=tag:Name,Values=${PREFIX}-igw --query InternetGateways[*].InternetGatewayId --output text)

aws ec2 detach-internet-gateway \
  --internet-gateway-id $IGW_ID \
  --vpc-id $VPC_ID

aws ec2 delete-internet-gateway \
  --internet-gateway-id $IGW_ID

# サブネット
PU_S1a_ID=$(aws ec2 describe-subnets \
  --filters Name=tag:Name,Values=${PREFIX}-public-subnet-1a \
  --query Subnets[*].SubnetId \
  --output text)

PU_S1c_ID=$(aws ec2 describe-subnets \
  --filters Name=tag:Name,Values=${PREFIX}-public-subnet-1c \
  --query Subnets[*].SubnetId \
  --output text)

PV_S1a_ID=$(aws ec2 describe-subnets \
  --filters Name=tag:Name,Values=${PREFIX}-private-subnet-1a \
  --query Subnets[*].SubnetId \
  --output text)

PV_S1c_ID=$(aws ec2 describe-subnets \
  --filters Name=tag:Name,Values=${PREFIX}-private-subnet-1c \
  --query Subnets[*].SubnetId \
  --output text)

aws ec2 delete-subnet \
  --subnet-id $PU_S1a_ID

aws ec2 delete-subnet \
  --subnet-id $PU_S1c_ID

aws ec2 delete-subnet \
  --subnet-id $PV_S1a_ID

aws ec2 delete-subnet \
  --subnet-id $PV_S1c_ID

# VPC
aws ec2 delete-vpc \
  --vpc-id $VPC_ID
