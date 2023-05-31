# 変数
## POLICY_ARNはコンソールから確認
PREFIX="sample01"
POLICY_ARN="arn:aws:iam::aws:policy/AdministratorAccess"

# ロールの作成
## ロールはjsonファイルを読み込む
aws iam create-role \
  --role-name ${PREFIX}-ec2-role \
  --assume-role-policy-document file://AssumeRole.json

## EC2にIAM権限を渡すのはIAMロールではなくIAMインスタンスプロファイル
aws iam create-instance-profile \
  --instance-profile-name ${PREFIX}-ec2-role

aws iam add-role-to-instance-profile \
  --instance-profile-name ${PREFIX}-ec2-role \
  --role-name ${PREFIX}-ec2-role

aws iam attach-role-policy \
  --role-name ${PREFIX}-ec2-role \
  --policy-arn $POLICY_ARN
