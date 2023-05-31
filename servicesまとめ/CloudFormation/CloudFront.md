# Amazon CloudFront  
HTMLファイルやCSS、画像、動画といった静的コンテンツをキャッシュし、オリジンサーバーの代わりに配信するCDNサービス。CDNであるので、元となるコンテンツを保持するEC2やELB、S3の静的ホスティング、オンプレミスなどのバックエンドサーバーが必要。  
  
クエリ文字を使用してオリジンに一定の情報を送信することでクエリ文字に応じて、処理を変更することができる。  
  
またCloudFrontではオリジンからコンテンツを取得するときにコンテンツの圧縮が可能で、ダウンロード時間が短くなり、コストも安くなる。
## ディストリビューション  
CloudFrontには配信する内容によって異なる2つのディストリビューションがある。  
- ダウンロードディストリビューション・・・HTTPやHTTPSを使ってHTMLやCSS、画像などのデータを配信する際に利用する。
  

- ストリーミングディストリビューション・・・RTMPを使って動画のストリーミング配信をする際に利用する。  

## キャッシュルール  
拡張子やURLパスごとにキャッシュ期間を指定することができる。頻繁にアップデートされる静的コンテンツはキャッシュ期間を短くし、あまり変更されていないコンテンツは長くするといった設定ができる。また動的サイトのURLパスはキャッシュを無効化することでCloudFrontをネットワーク経路としてだけ利用することも可能。  

## 用語  
- テンプレート
作成したAWSリソースがコード化されたテキストファイル。JSONまたはYAML形式で作成できる。
  
- スタック  
AWSリソースの集まりで、設計図となるテンプレートを元にこのスタックが形成される。  
  
- 変更セット  
すでに作成済みのスタックに対して変更を加える際、事前に差分を確認する機能がある。その変更内容を作成することを変更セットを作成すると呼ぶ。  

## テンプレート  
テンプレートセクション一覧
|  セクション  |    |  説明  |
|  --  |  --  |  --  |
|  AWSTemplateFormatVersion  |  オプション  |  テンプレートバージョン  |
|  Description  |  オプション  |  テンプレートの説明  |
|  Metadata  |  オプション  |  テンプレートに関する追加情報  |
|  Parameters  |  オプション  |  スタックの作成/更新する際にテンプレートへ渡す値  |
|  Mappings  |  オプション  |  キーと値のマッピング  |
|  Conditions  |  オプション  |  条件名と条件判断内容  |
|  Transform  |  オプション  |  サーバレスアプリケーションで使用  |
|  Resource  |  必須  |  スタックを構成するAWSリソースのプロパティ  |
|  Outputs  |  オプション  |  スタック構築後に出力させたい値  |

基本操作
- スタックの作成：テンプレートで定義された構成を作成
- スタックの変更：前回のテンプレートとの差分を適用
- スタックの削除：リソース全ての削除
- 変更セットの作成：前回テンプレートとの差分内容を作成
- 変更セットの実行：変更セットの内容を適用
- 変更セットの削除：作成した差分内容を削除

セクション
```
Resources:
  論理ID:
    Type: リソースタイプ
    Properties:
      リソースプロパティ
```

論理IDは英数字を利用したテンプレート内で一意の名前。リソースタイプは作成するAWSリソースを宣言する。(AWS::EC2::VPCなど) リソースプロパティはリソースに対して指定できる追加のオプション。

組み込み関数
`Ref`は指定したパラメータまたはリソースの値を返す。`!Ref 論理名`のように使う。
(組み込み関数リファレンス)[https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html]
## コマンドラインでの操作
テンプレートの検証
`aws cloudformation validate-template --template-body file://ファイルのパス`
スタックの作成
`aws cloudformation create-stack --stack-name techpit(スタックの任意の名前) --template-body file://vpc.yaml`
スタックの更新
`aws cloudformation update-stack --stack-name techpit --template-body file://vpc.yaml`
変更セットの作成
`aws cloudformation create-change-set --stack-name techpit --template-body file://vpc.yaml --change-set-name addSubnet`
変更セットの確認
`aws cloudformation describe-change-set --change-set-name addSubnet --stack-name techpit`
変更セットを作成・確認してから更新を行うことでスタックを更新する際に影響するリソースを確認できる。
変更セットの反映
`aws cloudformation execute-change-set --change-set-name addSubnet --stack-name techpit`

スタックの削除
`aws cloudformation delete-stack --stack-name techpit`

スタックの確認
`aws cloudformation describe-stacks`