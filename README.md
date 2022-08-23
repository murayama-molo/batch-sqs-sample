# batch-sqs-sample

s3->cloudwatch->batch->sqsのサンプル
※batch->sqsは未実装

<img width="783" alt="スクリーンショット 2022-08-23 21 08 34" src="https://user-images.githubusercontent.com/21980958/186154439-94df13b4-5375-4aac-a1ce-0fba4c17d746.png">

# Requirement

## OS

Mac か Ubuntu を利用してください

### Windows 環境の場合

- WSL
  - ディストリービューションは`Ubuntu`を使用すること

## aws

```bash
$ aws --version
aws-cli/2.2.25 Python/3.8.8 Darwin/21.5.0 exe/x86_64 prompt/off
```

## asdf

```bash
asdf --version
v0.10.2
```

## terraform

```bash
$ terraform -v
Terraform v1.2.5
on darwin_amd64
```

## python

```bash
$ python --version
Python 3.10.3
```

# Installation

すでにインストールされているツールはスキップしてください

## asdf をインストール

Google 等で OS に合った方法を検索しインストール

例：Ubuntu
https://qiita.com/salty-byte/items/e6fe2bbc748dff15de34

## AWS CLI

### AWS CLI をインストール

https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/getting-started-install.html

### IAM の設定

```bash
$ aws configure
AWS Access Key ID [None]: YOUR_ACCESS_KEY_ID
AWS Secret Access Key [None]: YOUR_SECRET_ACCESS_KEY
Default region name [None]: ap-northeast-1
Default output format [None]: json
```

## terraform

```bash
# プラグインをインストール
$ sudo -i asdf plugin add terraform

# インストール可能なバージョンの確認
$ sudo -i asdf list-all terraform

# バージョンを指定してインストール
$ sudo -i asdf install terraform 1.2.5

# バージョンを指定して適用
$ sudo -i asdf global terraform 1.2.5

# バージョン確認
$ terraform --verion
```

## python

```bash
# 事前準備（依存ファイルのインストール）
$ sudo apt update
$ sudo apt upgrade
$ sudo apt install build-essential libbz2-dev libdb-dev libreadline-dev libffi-dev libgdbm-dev liblzma-dev libncursesw5-dev libsqlite3-dev libssl-dev zlib1g-dev uuid-dev tk-dev

# プラグインをインストール
$ sudo -i asdf plugin add python

# インストール可能なバージョンの確認
$ sudo -i asdf list-all python

# バージョンを指定してインストール
$ sudo -i asdf install python 3.10.3

# バージョンを指定して適用
$ sudo -i asdf global python 3.10.3

# バージョン確認
python -V
```

# 初期設定

- ワークスペース名の設定を行う。
- デフォルトではユーザー名がワークスペース名として扱われる。

```bash
export TERRAFORM_WORKSPACE={TYPE_YOUR_OWN_WORKSPACE_NAME}
```

- Terraform のバックエンドに必要なリソースの作成と初期化処理を行う。

```bash
$ ./terraform/bin/entrypoint.sh init
```

# plan

apply するリソースの確認

```bash
$ terraform -chdir=terraform plan -var 'profile=default'
```

## domain を指定

```bash
$ terraform -chdir=terraform plan -var 'profile=default' -var 'domain_name=example.com' -var 'domain_name_certificate_arn=arn:aws:acm:ap-northeast-1:xxxxxxxxxxxx:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
```

# apply

```bash
$ terraform -chdir=terraform apply -var 'profile=default'
```

## domain を指定

```bash
$ terraform -chdir=terraform apply -var 'profile=default' -var 'domain_name=example.com' -var 'domain_name_certificate_arn=arn:aws:acm:ap-northeast-1:xxxxxxxxxxxx:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
```

# .env の設定

```bash
$ ./terraform -chdir=terraform/bin/entrypoint.sh env
```

## もう一度 apply して.env を反映

```bash
$ terraform -chdir=terraform apply -var 'profile=default'
```

## domain を指定

```bash
$ terraform -chdir=terraform apply -var 'profile=default' -var 'domain_name=example.com' -var 'domain_name_certificate_arn=arn:aws:acm:ap-northeast-1:xxxxxxxxxxxx:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
```

# destroy

お掃除
作ったリソースを全部削除

```bash
$ terraform -chdir=terraform destroy -var 'profile=default'
```
