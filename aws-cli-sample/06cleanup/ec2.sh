#EC2
PREFIX="sample01"
## 複数ある場合は注意
INSTANCE_ID=$(aws ec2 describe-instances \
  --filter Name=tag:Name,Values=${PREFIX}-web-01 \
  --query  "Reservations[*].Instances[*].InstanceId"\
  --output text)

## 削除保護を無効化
aws ec2 modify-instance-attribute\
   --instance-id $INSTANCE_ID \
   --no-disable-api-termination

aws ec2 terminate-instances \
--instance-ids $INSTANCE_ID

## AMI
## 以下のコマンドで探す(なぜかフリーズしてしまうので今回はマネコンから削除した)
aws ec2 describe-images

## snapshot
SNAP_SHOT_ID=$(aws ec2 describe-images \
  --filter "Name=tag:Name,Values=${PREFIX}-web-01" \
  --query="Images[].[ImageId,BlockDeviceMappings[].Ebs[].[SnapshotId]]" \
  --output=text) && echo $SNAP_SHOT_ID

aws ec2 delete-snapshot --snapshot-id $SNAP_SHOT_ID


# security group
## 可能ならコンソールからやったほうが楽
SG_ID=$(aws ec2 describe-security-groups --filters Name=tag:Name,Values=${PREFIX}-ec2-sg --query "SecurityGroups[*].GroupId" --output text) && echo $SG_ID

## デタッチ
aws ec2 modify-instance-attribute \
--instance-id $INSTANCE_ID \
--groups $SG_ID

## 削除
aws ec2 delete-security-group \
--group-id $SG_ID

# KeyPair
KeyName=$(aws ec2 describe-key-pairs --filters Name=key-name,Values=sample01-key  --query "KeyPairs[*].KeyName" --output text)
aws ec2 delete-key-pair \
  --key-name $KeyName