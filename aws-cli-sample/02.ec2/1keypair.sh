# 変数
PREFIX="sample01"

# keypairの作成
aws ec2 create-key-pair\
  --key-name ${PREFIX}-key\
  --query "KeyMaterial"\
  --output text > ${PREFIX}-key.pem