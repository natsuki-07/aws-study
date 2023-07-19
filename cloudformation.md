# CloudFormationまとめ
CloudFormationはプログラミング言語やテキストファイルを使用してAWSリソースを自動で構築するサービス

## テンプレート
テンプレートはjsonまたはyamlで記述していく

### 疑似パラメータ
疑似パラメータはAWS CloudFormationにより事前に定義されたパラメータでパラメータと同じようにRef関数の引数として使用する。

|  Reference Value  |  Description  |  Example Returned Value  |
|  --  |  --  |  --  |
|  AWS::AccountId  |  スタックが作成されるアカウントのIDを返す  |  123456789  |
|  AWS::Region  |  リソースが作成されているリージョン  |  us-east-1  |
|  AWS::StackId  |  スタックのID  |  arn:aws:cloudformation:us-east-1:123456789:stack/MyStack/1f28gqfo834fv  |
|  AWS::StackName  |  スタックの名前  |  MyStack  |
|  AWS::NotificationARNs  |  スタックの通知ARNリストを返す  |  [aen:aws:sns:us-east-1:123456789:MyTopic]  |
|  AWS::NoValue  |  `Fn::If`の戻り値として指定すると対応するリソースプロパティを削除する  |  返り値無し  |
|  AWS::Partition  |  リソースがあるパーティションを返す  |  標準のリージョンの場合 ->aws  |
|  AWS::URLSuffix  |  ドメインサフィックスを返す  |  amazonaws.com  |


### Parameters
パラメータを使用するとスタックを作成、更新する際にテンプレートにカスタム値を入力できる。
また`Fn::Ref(!Ref)`を使用してparametersの値を参照できる。`NoEcho`プロパティをtrueにして設定しておくとパラメータ値はコンソールに表示されない。

```yml
Parameters:
  InstanceTypeParameter:
    Type: String
    Default: t2.micro
    AllowedValues:
      - t2.micro
      - m1.small
      - m1.large
    Description: Enter t2.micro, m1.small, or m1.large. Default is t2.micro.
  MyPassword:
    Type: String
    NoEcho: true
```
[パラメータ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html)

### Resources
Resourcesは必須項目でCloudFormationテンプレート内で作成するAWSリソースの定義を記述する。具体的には、各リソースのタイプ、プロパティ、およびリソース間の関係を指定する。

リソースはリソースタイプごとに作成し`Type`を指定する。具体的な設定は`Properties`で指定していく。

##### リソース属性
- DependsOn   指定したリソースが作成されてからリソースを作成する
- DeletionPolicy  スタック削除時に削除するか保持するかなどを指定
- UpdatePolicy  特定のリソースでCloudFormationが処理する方法を指定できる
- UpdateReplacePolicy  スタックアップデートする際にリソースを作り直すかそのままにするか
- CreationPolicy  指定数のシグナルを受信するかタイムアウトになるまで作成完了ステータスにならないようにする
- Metadata  構造化データを関連付ける

```yml
Resources:
  MyEC2Instance:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: ami-12345678
      InstanceType: t2.micro
      KeyName: my-key-pair

  MyS3Bucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: my-bucket
      AccessControl: Private
```


[リソース](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resources-section-structure.html)

### Mappings
リソースのプロパティや条件に基づいて値をマッピングするために使用される。

`Fn::FindInMap`関数を使用して値を使用できる。
!FindInMap [MapName, TopLevelKey, SecondLevelKey]

```yml
Mappings:
  RegionMap:
    us-east-1:
      AMI: ami-0123456789abcdef0
    us-west-2:
      AMI: ami-abcdef0123456789

Resources:
  myEC2Instance:
    Type: "AWS::EC2::Instance"
    Properties:
      ImageId: !FindInMap [RegionMap, !Ref "AWS::Region", AMI]
      InstanceType: m1.small
```
[マッピング](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/mappings-section-structure.html)

### Outputs
他のスタックでインポートして使用できる値を宣言する。
```yml
Outputs:
  StackSSHSecurityGroup:
    Description: The SSH Security Group for our company
    Value: !Ref MyCompanyWideSSHSecurityGroup
    Export:
      Name: SSHSecurityGroup
```

他のテンプレートで参照したいときは `!ImportValue エクスポート名`で参照できる。

```yml
Resources: 
  WebServer:
    Type: AWS::EC2::Instance
    Properties:
      KeyName: !Ref KeyName
      ImageId: !Ref EC2AMIId
      InstanceType: t2.micro
      SubnetId: !ImportValue SubnetName
      SecurityGroupIds:
        - !ImportValue StackSSHSecurityGroup
      Tags:
        - Key: Name
          Value: WebServer
```
[アウトプット](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html)
### Condition
条件を作成し条件分岐によりtrueのときのみリソースや出力を作成するようにできる。

以下の例の場合、`EnvType`が`prod`ならtrueとなりVolumeがインスタンスにアタッチされる。
```yml
Conditions:
  CreateProdResources: !Equals [ !Ref EnvType, prod ]

Resources:
  EC2Instance:
    Type: AWS::EC2::Instance

  MountPoint:
    Type: AWS::EC2::VolumeAttachment
    Condition: CreateProdResources
    Properties:
      InstanceId: !Ref EC2Instance
```
`!Equals`以外の組み込み条件関数はこちらを参照([条件関数](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-conditions.html))

[コンディション](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/conditions-section-structure.html)

### Rules
スタックを作成したりアップデートする際に、テンプレートに送信されたパラメータまたはパラメータの組み合わせを検証する。ルール固有の組み込み関数を使用して、ルール条件とアサーションを定義できる。

次の例ではEnvironmentの値がprodかdevで別のインスタンスを作成するようにしている。
```yml
Parameters:
  InstanceType:
    Type: String
    Default: t2.small
    AllowedValues:
      - t2.nano
      - t2.micro
      - t2.small

  Environment:
    Type: String
    Default: dev
    AllowedValues:
      - dev
      - prod
      
Rules:
  ProdInstanceType:
    RuleCondition: !Equals 
      - !Ref Environment
      - prod
    Assertions:
      - Assert:
          !Equals [t2.small, !Ref InstanceType]
        AssertDescription: 'For a production environment, the instance type must be t2.small'

  DevInstanceType:
    RuleCondition: !Equals 
      - !Ref Environment
      - dev
    Assertions:
      # Assert with Or
      # - Assert:
      #     'Fn::Or':
      #       - !Equals [!Ref InstanceType, t2.nano]
      #       - !Equals [!Ref InstanceType, t2.micro]
      # Assert with Contains
      - Assert:
          'Fn::Contains':
            - - t2.nano
              - t2.micro
            - !Ref InstanceType
        AssertDescription: 'For a development environment, the instance type must be t2.nano or t2.micro'
```

[ルール](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/rules-section-structure.html)
[ルール関数](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-rules.html)

### Metadata
Metadataセクションではテンプレートの詳細を提供する任意のJSONまたはYAMLオブジェクトを含めることができる。

```yml
Metadata:
  Instances:
    Description: "Information about the instances"
  Databases: 
    Description: "Information about the databases"
```

CloudFormation固有のメタデータキーも存在する。

- AWS::Cloudformation::Init  cfn-initヘルパースクリプトの構成タスクを定義。[AWS::CloudFormation::Init](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-init.html)
- AWS::CLoudFormation::Interface  コンソールに表示される場合の入力パラメータのグループ化と順序を定義する。
- AWS::CloudFormation::Designer  CloudFormationデザイナーでリソースがどのように配置されるかの情報
- AWS::CloudFormation::Authentication  AWS::Cloudformation::Initで指定したファイルまたはソースの認証情報を指定する。[AWS::CloudFormation::Authentication](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-authentication.html)

`AWS::Cloudformation::Init`と`UserData`の違いはUserDataの場合はコマンドの成否はスタックの成否に影響せずコマンドが失敗してもスタックは成功ステータスになる。反対にcfn-initはcfn-signalと組み合わせることで定義したコマンドの実行成否はスタックの成否に影響するようになる。


[メタデータ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/metadata-section-structure.html)

### Outputs
他のスタックにエクスポートするに利用され出力値を宣言する。

最大で200個まで宣言できvalueが必須となる
```yml
Outputs:
  SSHGroupId:
    Value: !Ref SSHSecurityGroup
    Description: Id for the SSH Security Group
```

インポートする側
```yml
Resources:
  EC2Instance:
    Type: AWS::EC2::Instance
    Properties:
      InstanceType: t2.micro
      ImageId: !Ref ImageId
      SecurityGroupIds:
        - !GetAtt SSHSecurityGroupStack.Outputs.SSHGroupId
```

[出力](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html)

### Custom Resources
テンプレートにカスタムのプロビジョニングロジックを記述しユーザーがスタックを作成、更新、削除するたびにCloudFormationがそれを実行する。
例えばCloudFormationのリソースタイプとして使用できないリソースを含める必要がある場合、カスタムリソースを使用して含めることができる。

- カスタムリソースの仕組み
template developerがカスタムリソースとサービストークンを含むテンプレートを作成する。テンプレートを使用してカスタムリソースを使用するたびにCloudFormationは指定のサービストークンに要求を送信する。  
LambdaやAmazon SNSのリソースプロバイダがリクエストを処理し、`SUCCESS`または`FAILED`の応答を署名付きURLに返す。また応答をJSONでS3URLにアップロードする

`SUCCESS`を取得した場合CloudFormationはスタック操作を続ける。
```json
// リクエスト
{
   "RequestType" : "Create",
   "ResponseURL" : "http://pre-signed-S3-url-for-response",
   "StackId" : "arn:aws:cloudformation:us-west-2:123456789012:stack/stack-name/guid",
   "RequestId" : "unique id for this create request",
   "ResourceType" : "Custom::TestResource",
   "LogicalResourceId" : "MyTestResource",
   "ResourceProperties" : {
      "Name" : "Value",
      "List" : [ "1", "2", "3" ]
   }
}
// レスポンス
{
   "Status" : "SUCCESS",
   "PhysicalResourceId" : "TestResource1",
   "StackId" : "arn:aws:cloudformation:us-west-2:123456789012:stack/stack-name/guid",
   "RequestId" : "unique id for this create request",
   "LogicalResourceId" : "MyTestResource",
   "Data" : {
      "OutputName1" : "Value1",
      "OutputName2" : "Value2",
   }
}
```

[カスタムリソース](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/template-custom-resources.html)

### Dynamic Reference
動的な参照を使用することでSystems ManagerパラメータストアやAWS Secrets Managerなどのほかのサービスで管理されている値をテンプレートに指定できる。(最大60個まで)
  
次のパターンのように記述する  
`{{resolve:service-name:reference-key}}`または`{{resolve:ssm:[a-zA-Z0-9_.\-/]+(:\d+)?}}`

[動的な参照](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/dynamic-references.html)

### Modules
CloudFormationのテンプレートをCloudFormationレジストリに登録して別のテンプレートで再利用する機能。  
`cfn init`でひな形の作成。fragmentsディレクトリ配下のsample.jsonをリネームしJSON形式テンプレートを記述し、`cfn submit`してレジストリに登録する。
  
別のテンプレートからは`MyCompany::s3::bucket::MODULE`のような形で参照することができる

### デザイナー
テンプレートを作成するためのグラフィックツール。リソースを可視化でき、ドラッグアンドドロップインターフェイスを使用してテンプレートリソースを図示し更新できる。

### ドリフト
スタックでドリフト検出オペレーションを実行するとスタックが予想されるテンプレート構成からドリフトしたかどうかが判断され、ドリフト検出をサポートするスタック内の各リソースのドリフトステータスに関する詳細情報が返される。
　　
スタックの詳細画面でドリフトの検出をすることで使用できる。

### StackSets
スタックセットでは1つのテンプレートで複数のリージョンのAWSアカウントにスタックを作成できる。スタックセットを定義したら、指定したターゲットアカウントやリージョンでスタックを作成、更新、削除できる

StackSetsでは複数アカウントのスタックを管理する管理アカウントが存在し、そのアカウントからターゲットアカウントに対してスタックの操作の命令を実行する。

### Macros
Lambda関数を使用してテンプレートの記法を拡張できる機能。

マクロの定義の作成
```yml
Type: "AWS::CloudFormation::Macro"
Properties:
  Description: String
  FunctionName: String
  LogGroupName: String
  LogRoleARN: String
  Name: String　// リージョン内でユニーク
```

[CloudFormationのマクロ機能でLambda関数と一緒にCloudWatch LogsのLog Groupを自動作成してみる](https://dev.classmethod.jp/articles/craete-log-group-by-cfnmacro/)
[マクロ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/template-macros.html)

### Resource Types
サードパーティーのリソースをテンプレートで使えるようにする。

[リソースタイプ](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html?icmpid=docs_cfn_console)

### Rain
AWS CloudFormation のコマンドラインツール。進捗がわかるなどAWS CLIのちょっと辛い部分をカバーしてくれる。 

[rain](https://aws-cloudformation.github.io/rain/)

#### Functions
- `Fn::Ref`  指定したパラメータまたはリソース(id)の値を返す
- `Fn::GetAtt` リソースから属性の値を返す
- `Fn::FindInMap` Fn::FindInMap: [ MapName, TopLevelKey, SecondLevelKey ] Mappingsセクションで宣言されたキーに対応する値を返す
- `Fn::ImportValue`  別のスタックでエクスポートされた出力の値を返す
- `Fn::join`  一連の値を特定の区切り文字で区切って値に追加する(!Join [":",[a,b,c]] => "a:b:c")
- `Fn::Base64`  入力文字列をBase64表現で返す
- `Fn::Cidr`  アドレスブロックのCIDRを返す。`!Cidr [ ipBlock, count, cidrBits ]`
- `Fn::GetAZs`  指定したリージョンのアベイラビリティーゾーンをアルファベット順にリストした配列で返す
- `FnSelect`  オブジェクトのリストから 1 つの値を返す。`!Select[index, listOfObjects]`
- `Fn::Split`  文字列をリストに分割する
- `Fn::Length`  配列の要素数を返す
- `Fn::Sub`  入力文字列の変数を指定した値に置き換える
- `Fn::ToJsonString`  オブジェクトまたは配列を対応するJSON文字列に変換する
- `Fn::Transform`  スタックテンプレートの一部に対してカスタム処理を実行するためのマクロを指定する

[組み込み関数](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html)