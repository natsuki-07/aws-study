# サーバーレス
サーバーレスアーキテクチャはサーバがないというわけではなく、サーバーを意識しなくてもよいアーキテクチャのこと。  
  
## AWS SAM
SAMはCloudFormationの拡張機能で、Lambda関数、API Gateway、DynamoDBテーブル、S3バケット、Step Functionsなどを組み合わせたサーバレスアプリケーションの構築を自動化することによって素早くデプロイし、開発スピードを向上させ整合性を保つことに役立つ。  
SAMは専用のCLIを使用する。最もシンプルなデプロイは`sam init` -> `sam build` -> `sam deploy`の3ステップ  
  
sam initによりサーバレスアプリケーションの初期処理をする。初期処理ではディレクトリとファイルが作成される。SAMはCloudFormationの拡張機能で、CloudFormationと同様にYAMLまたはJSON形式でテンプレートファイルを記述する。sam buildによりAPIとLambda関数をデプロイするための準備をする。ビルドが完了するとテストも実行できるようになる。sam deployによりAWSアカウントにAWSリソースを構築する。  
  
本番環境にデプロイする前に開発環境でテストしたいという要件があるときは`sam local start-api`を実行すると開発環境でサーバレスアプリケーションのテストができる。

