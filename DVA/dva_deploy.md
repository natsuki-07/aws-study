# デプロイ
## CI/CDパイプライン
- CI(継続的インテグレーション)  
ソースコードを開発し、リポジトリに新規に登録すること、変更して更新することなどを一般的にチェックインという。  
ソースコードを継続的にチェックインし、ビルドとテストを自動化し、コードを検証する方法を継続的インテグレーションという。要は、頻繁にプログラムを更新し、コンパイルやテストを行うといった定型的な作業は自動化するということ。  
  
- CD(継続的デプロイメント、継続的デリバリー)  
継続的インテグレーションは、継続的デプロイメントに含まれる。開発・更新したソースコードが本番環境でお客様が安全に使える状態には反映される。テスト環境へのデプロイ、本番環境へのデプロイ、リリースまで自動化する。自動化することにより、デプロイが頻繁に繰り返し発生したとしてもボトルネックや遅延、リスク原因にならないようにすることができる。  
  
## AWS コードサービス
### AWS CodeCommit
Gitベースのリポジトリを提供するサービス。リポジトリを作成でき、作成したリポジトリは開発環境からgitコマンドによって操作できる。  
  
CodeCommitのリポジトリにはSSHまたはHTTPSを使って安全に接続できる。SSH,HTTPSで使用する認証情報はIAMユーザーごとに生成する。IAMポリシーによってリポジトリのアクセス権限を設定することができる。IAMには管理ポリシーとして`AWSCodeCommitPowerUser`が用意されている。  
  
またソースコードが更新されたなどのタイミングで、通知やLambda関数を実行するイベントを設定できる。通知の対象はSNSとChatbot。  
  
### AWS Codebuild
ソースコードのコンパイル、テスト、ソフトウェアパッケージの作成を実行する。他のマネージドサービスと同様にリクエスト量が多くなっても対応できるスケーラビリティとビルドした分にだけコストが発生する従量課金というところがクラウドのメリットでもあり特徴でもある。  
  
ビルド対象のソースはS3, GitHub Enterprise, CodeCommit, Bitbucket, GitHubより選択することができる。  
  
ソースのルートレベルに`buildspec.yml`というファイルを設置する。buildspecはビルドの使用であり、ビルドプロセスのコマンドを記述する。  
  
CodeBuildローカルエージェントを使用してローカルマシンでCodeBuildを実行できる。メリットとしてはbuildspecの整合性と内容をローカルでテストできることやコミットする前にアプリケーションをローカルでテストしてビルドできる、ローカル開発環境からエラーを素早く特定して修正できることなどがある。  
  
### AWS CodeDeploy
EC2インスタンス、オーとスケーリング、オンプレミスサーバー、ECS、LambdaへS3、GitHubからリビジョンをデプロイする。  
  
Application Specification File(AppSpec file)はCodeDeployがEC2インスタンスに対してS3またはGitHubにあるアプリケーションのリビジョンをどのようにインストールするか決定するYAMLフォーマットのファイルで、デプロイの様々なライフサイクルイベントをフックして処理を実行するか決定する。  
  
### AWS CodePipeline
迅速かつ信頼性の高いアプリケーション更新を実現する。コードが変更されるたびにビルド、テスト、デプロイをする。各AWS Codeサービスを連携させることも、他のサービスやサードパーティーサービスとの連携も可能。  
ソースプロバイダは、CodeCommit, ECR, S3, Bitbucket, GitHubから選択できる  
ビルドプロバイダはCodeBuild, Jenkinsから  
デプロイプロバイダはCodeDeploy, AppConfig, CloudFormation, Elastic Beanstalk, OpsWorks, Service Catalog, Alexa Skills Kit, ECS S3から  
  
### AWS CodeStar
AWS CodeStarではプロジェクトテンプレートを選択して、プロジェクト名を決めるだけで、各AWS Codeサービスを構成したCI/CDパイプラインを自動的に作成する。迅速にプロジェクトを開始できるサービス。  
  
### AWS CodeArtifact
アーティファクトリポジトリサービス。ソフトウェアパッケージを保存して配信できるサービス。また、一般的に使用されるパッケージマネージャおよびビルドツールと連携して動作する。  
  
### AWS CodeGuru
CodeGuru ProfilerとCodeGuru Reviewerという2つの機能がある。  
  
CodeGuru ProfilerはEC2,EKS,ECS,Fargate,LambdaまたはオンプレミスのJava,JVM言語で開発されたアプリケーションのパフォーマンスを可視化する。アプリケーションのパフォーマンスの問題の原因を診断することができる。  
  
CodeGuru ReviewerはGitHub, GitHub Enterprise, CodeCommit, Bitbucketと連携し、Javaのコードの自動レビューを実行する。

### ElastiBeanstalk 
#### EB CLI
EB CLIコマンドからもElastic Beanstalkアプリケーション、環境構築ができ、継続的なデプロイも可能。  
- eb init・・・アプリケーションを作成する
```
eb init -p python-3.6 flask-tutorial --region us-east-1
```
  
- eb create・・・環境名を指定して、アプリケーションの環境を作成する。
```
eb create flask-env
```
  
- eb deploy
```
eb deploy -I v2
```
  
`.ebextensions`を追加すると環境のカスタマイズができる。コマンドを実行するディレクトリに.ebextensionsディレクトリを作成し、その配下に拡張子を.configとするJSONもしくはYAMLフォーマットのファイルを作成する。