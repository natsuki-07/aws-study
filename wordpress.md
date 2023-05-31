# AWS VPC構築からWordPressのインストールまで
マルチAZ構成でVPCを構築しEC2上にWordPressをインストールするところまで  
  
＊アカウント作成時のIAMや請求の設定などは割愛
  
## VPC
VPCウェザードを起動から始める。パブリックサブネットとプライベートサブネットを持つVPCを選択する。設定は基本デフォルトのまま  
  
IPv4 CIDR ブロック->10.0.0.0/16
パブリックサブネットの IPv4 CIDR->10.0.0.0/24

Elastic IPの割り当てはVPCの作成前に事前にElastic IPを作成しておき、それを割り当てる。  
その後VPCの作成  
  
パブリックサブネットとプライベートサブネットが作成される。パブリックサブネットのルートテーブルを見るとnatゲートウェイを見るようになっているのでルートテーブルの関連付けを編集してインターネットゲートウェイを設定する。  
  
＊NATゲートウェイは料金がかかってしまうので、一旦削除して使用するときに再度作成するといい  
  
今回はマルチAZ構成なので別AZにパブリックサブネットとプライベートサブネットを追加で作成する。  
  
サブネットを作成より作成したVPCを選択。サブネット名とAZを指定し、IPv$ CIDRブロックは10.0.2.0/24, 10.0.3.0/24とする。  
  
プライベートサブネットCにNATゲートウェイを割り当てる。(お金がかかってしまうので後回しでも可)ルートテーブルを見るとNATゲートウェイがブラックホールになっている可能性がある。設置後にNATゲートウェイを削除した場合になるので、新たに作成したものにする。  
  
次にネットワークACLの作成をする。すべてdenyになっているのでインバウンドルールの編集からSSH,HTTP,HTTPSを許可するように設定する。さらにえふぁめるポートの設定もする。エファメルポートはタイプはカスタムTCPルールでポート範囲は1024-65535とする。アウトバウンドも同じようにする。作成したらサブネットの関連付けを選択し作成した4つのサブネットに関連付けする。  
  
## EC2インスタンスの起動
インスタンスの起動からLinux2 AMIを選択、次にt2micro、作成したVPC設置したいAZを選択し、パブリックサブネットの場合は自動割り当てパブリックIPを有効にする。ほかはデフォルト。  
  
ストレージは汎用SSDを選択->タグで名前を付ける->新しいセキュリティグループを作成する(最初だけ、その後は既存のものを使用)。セキュリティグループはSSH,HTTP,HTTPSを入れる。その後新しいキーペアを作成しダウンロードしてからインスタンスの作成する。  
  
接続するにはパブリック IPv4 アドレスをコピーしteratermでログインする。ユーザー名は`ec2-user`でパスワードはダウンロードした秘密鍵を使用する。

## Apachサーバーの設定
tera termでログインした状態で、`sudo su`->`yum update -y`をする  
  
`yum install httpd -y`でアパッチのインストール  
`service httpd start`で起動  
`cd /var/www/html`にwebサイトの作成をする  
`nano index.html`で編集し、htmlを作成。ctr+xで終了し、YしてEnterで抜けれる  
`service httpd restart`で再起動  
パブリック IPv4 アドレスにアクセスすると見れるようになっている。

## MySQLの設定
プライベートサブネットにEC2インスタンスを起動。だいたい同じだがセキュリティグループは新しく作成し、SSHとMYSQLを追加する。キーペアは既存のもので良い

tera termに戻る。パブリックサブネットからpemキーを利用してプライベートサブネットにアクセスできるようにする。  
`nano myprivatekey.pem`でpemファイルを作成し、既存のキーをすべてコピペする。  
`chmod 400 myprivatekey.pem`で読み取り権限の付与  
`ssh ec2-user@10.0.1.12 -i myprivatekey.pem`でパブリックからプライベートにアクセス(10.0.1.12はプライベートのIPアドレス)

NATゲートウェイが必要になる。パブリック側にNATゲートウェイを設置。ルートテーブルのルートを編集する。
  
再びtera termのプライベートの方に入り、`sudo su`,`yum update -y`をする  
`yum localinstall https://dev.mysql.com/get/mysql80-community-release-el7-1.noarch.rpm -y`でMYSQLのインストール     
    
`yum install -y mysql-community-server`コミュニティバージョンもダウンロード
ダウンロードが終わったらお金がかかるのでNATゲートウェイとElastic IPを削除しても良い

## LAMP環境の設定
tera termでパブリックサブネットにログイン   
`sudo su`->`cd var/www/html`->`rm index.html`   
`systemctl start httpd`アパッチの起動   
`systemctl enable httpd`インスタンスが起動するたびに自動でアパッチも起動するように設定  
`amazon-linux-extras install php7.2`、`yum install -y php`でPHPをインストール    
`yum localinstall https://dev.mysql.com/get/mysql80-community-release-el7-1.noarch.rpm -y`  
`yum install -y mysql-community-server`     

`systemctl start mysqld`起動    
`systemctl enable mysqld`   
    
`cat /var/log/mysqld.log | grep localhost`で仮パスワードの発行
`mysql -u root -p`でパスワードを入力してログインする
`ALTER USER root@localhost identified by 'パスワード';`パスワードを設定

`CREATS USER udemy@localhost identified with mysql_native_password by 'パスワード'`ワードプレス用にユーザーを作成

`GRANT ALL PRIVILEGES ON udemy.+ TO udemy@localhost;`権限をあたえる
`FLUSH PRIVILEGES;`権限を確定させる

## WordPressのインストール
`wget https://ja.wordpress.org/latest-js.tar.gz`
`tar -xzvf latest-ja.tar.gz`解凍する
`cp -r wordpress/* /var/www/html`移動させる
`chown apach:apache /var/www/html/ -R`権利をapachに渡す
`systemctl restart httpd.service`
パブリックIPアドレスでWordPressをブラウザで表示させログインする