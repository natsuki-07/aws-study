# 独自ドメインが必要
#!/bin/bash
set -euo pipefail

# Variables
MY_DOMAIN="sample01.20230331"

# ホストゾーンの作成
## caller referenceは同一名称のドメインを意図せず複数作成してしまうことを介するためにID
HOSTED_ZONE_ID=$(aws route53 create-hosted-zone \
  --name $MY_DOMAIN \
  --caller-reference "$(date +%Y-%m-%d_%H-%M-%S)" \
  --query "HostedZone.Id" --output text) && echo $HOSTED_ZONE_ID

# NSレコード
## filterが使えないのでqueryで絞り込む
## 取得したネームサーバーはプロバイダーに登録する
aws route53 list-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --query 'Resourc[?Type==`NS`].ResourceRecords[*].Value'

# ACM
## *.${MY_DOMAIN}でサブドメインにも対応
CERTIFICATE_ARN=$(aws acm request-certificate \
  --domain-name *.${MY_DOMAIN} \
  --validation-method DNS \
  --query "CertificateArn" --output text) && echo $CERTIFICATE_ARN

## 検証に使うレコードのネームとバリューを取得
VALIDATION_RECORD_NAME=$(aws acm describe-certificate \
  --certificate-arn $CERTIFICATE_ARN \
  --query "Certificate.DomainValidationOptions[*].ResourceRecord.Name" --output text) && echo $VALIDATION_RECORD_NAME

VALIDATION_RECORD_VALUE=$(aws acm describe-certificate \
  --certificate-arn $CERTIFICATE_ARN \
  --query "Certificate.DomainValidationOptions[*].ResourceRecord.Value" --output text) && echo $VALIDATION_RECORD_VALUE

## DNS認証
# Update record sets file
VALIDATION_RECORD_FILE=./dnsvalidation.json
## 置換
sed -i -e "s/%VALIDATION_RECORD_NAME%/$VALIDATION_RECORD_NAME/" $VALIDATION_RECORD_FILE
sed -i -e "s/%VALIDATION_RECORD_VALUE%/$VALIDATION_RECORD_VALUE/" $VALIDATION_RECORD_FILE

# Add record sets
## change-resource-record-setsで作成、更新、削除ができる
aws route53 change-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --change-batch file://$VALIDATION_RECORD_FILE

# 置換したもの初期化して元に戻しておく
git restore $VALIDATION_RECORD_FILE
