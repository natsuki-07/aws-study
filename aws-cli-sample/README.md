# AWS CLIでの環境構築
[aws cli　リファレンス](https://awscli.amazonaws.com/v2/documentation/api/latest/index.html)

## インストール
aws cli v2を使用するのでv1がある場合はuninstallしておく
```
sudo pip uninstall awscli -y
```

[aws cli インストール](https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/getting-started-install.html)
```
# linuxの例
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
# aws-cli/2.11.6
```

認証情報の設定
IAMユーザーを作成しaccess key, secret access keyなどを登録する。
```
aws configure
```

## 作成する構成
基本的にフォルダの上からコマンドを実行することで作成できる。

### 1. VPC
- VPCとインターネットゲートウェイの作成
- パブリックサブネットの作成
- ルートテーブルの作成とサブネットの関連付け

### 2. EC2
- キーペアの作成
- IAMロール、インスタンスプロファイルの作成とポリシーの追加
- セキュリティグループの作成
- EC2の作成
- AMIの作成

### 3. route53
作成手順
1. 独自ドメインの名前でホストゾーンを作成する
2. ネームサーバーを登録する
3. ACMでSSL証明書を発行する
4. このSSL証明書で保護するドメインの所有者を検証するためにRoute53でDNS認証を行うためのCNAMEレコードを作成する
5. ELBを作成したのちに独自ドメインで接続するためのALIASレコードを登録する

### 4. ELB
- ELBの作成
- ターゲットグループの作成と登録
- レコードセットの作成

### 5. RDS
- プライベートサブネットとルートテーブルの作成
- パラメータグループ、オプショングルーの作成
- ロールの作成
- DBインスタンスの作成

## filters,query, output
作成したらfilterやqueryを使用してidを抜き出し変数として持っておく。
- --filters 出力結果を絞り込み 
filtersはsql文のWhere句に似たもの。`--filters Name=string,Values=string`で指定する

- --query 出力項目を絞り込み 
sql文のカラム指定的なもの。`--query JMESPath`で指定する
[JMESPath](https://jmespath.org/)

- --output 出力形式の指定 
`--output json/text/table/yaml`で指定する。指定しない場合は`aws configure`で設定した形式となる


`変数名=$()`でカッコ内にコマンドを記述し変数に指定できる

```
VPC_ID=$(aws ec2 describe-vpcs \
--filters Name=tag:Name,Values=${PREFIX}-vpc \　Nameタグで絞り込み
--query "Vpcs[*].VpcId" \
--output text)
```
