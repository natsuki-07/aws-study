PREFIX="sample01"

# RDS関連の削除
## 削除保護の無効化
aws rds modify-db-cluster \
  --db-cluster-identifier ${PREFIX}-db-instance\
  --no-deletion-protection

aws rds delete-db-instance \
  --db-instance-identifier ${PREFIX}-db-instance \
  --skip-final-snapshot \
  --delete-automated-backups

## オプショングループの削除
aws rds delete-option-group \
  --option-group-name ${PREFIX}-option-group

## パラメータグループ
aws rds delete-db-parameter-group \
  --db-parameter-group-name ${PREFIX}-parameter-group

## サブネットグループ
aws rds delete-db-subnet-group \
  --db-subnet-group-name ${PREFIX}-subnet-group

