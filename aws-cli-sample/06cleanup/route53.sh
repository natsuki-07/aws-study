# レコード
## 複数作成してある場合注意
CERTIFICATE_ARN=$(aws acm list-certificates \
  --query "CertificateSummaryList[0].CertificateArn" \
  --output text) && echo $CERTIFICATE_ARN

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

# ACM
aws acm delete-certificate\
  --certificate-arn $ACM_AEC

# ホストゾーン
HOST_ZONE_ID=$(aws route53 list-hosted-zones \
  --query "HostedZones[0].Id" \
  --output text)

aws route53 delete-hosted-zone \
  --id $HOST_ZONE_ID