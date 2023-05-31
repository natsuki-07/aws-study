PREFIX="sample01"

# ELB
## ターゲットグループ
TARGET_GROUP_AEN=$(aws elbv2 describe-target-groups \
  --query "TargetGroups[*].TargetGroupArn" \
  --output text)

aws elbv2 delete-target-group \
--target-group-arn $TARGET_GROUP_AEN

## ロードバランサー
LOAD_BALANCER_ARN=$(aws elbv2 describe-load-balancers \
  --query "LoadBalancers[*].LoadBalancerArn"\
  --output text) && echo $LOAD_BALANCER_ARN

aws elbv2 delete-load-balancer \
  --load-balancer-arn $LOAD_BALANCER_ARN