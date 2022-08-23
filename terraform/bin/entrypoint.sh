#!/usr/bin/env sh
set -eu

DEBUG=${DEBUG:-false}
TERRAFORM_WORKSPACE=${TERRAFORM_WORKSPACE:-$(whoami)}
TERRAFORM_SHOULD_APPLY=${TERRAFORM_SHOULD_APPLY:-false}

current_dir=$(cd "$(dirname "$0")";pwd)
terraform_dir="$current_dir/.."

if "$DEBUG"; then
  set -x
fi

fetch_backend_bucket_name() {
  (
    aws_account_id=$(aws sts get-caller-identity --query "Account" --output text)
    echo "batch-sqs-sample-tfstate-in-$aws_account_id"
  )
}

make_bucket() {
  (
    s3_bucket_name=$(fetch_backend_bucket_name)
    if aws s3api head-bucket --bucket "$s3_bucket_name" >/dev/null 2>&1; then
      echo "S3 Bucket '$s3_bucket_name' already exists."
      return
    fi

    echo "S3 Bucket '$s3_bucket_name' does not exist."
    aws s3 mb "s3://$s3_bucket_name"
    aws s3api put-public-access-block \
      --bucket "$s3_bucket_name" \
      --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
    aws s3api put-bucket-versioning \
      --bucket "$s3_bucket_name" \
      --versioning-configuration Status=Enabled
    aws s3api put-bucket-lifecycle-configuration \
      --bucket "$s3_bucket_name" \
      --lifecycle-configuration "file://$current_dir/archive_rule.json"
  )
}

create_table() {
  (
    table_name="batch-sqs-sample-state-locking"
    if aws dynamodb describe-table --table-name "$table_name" >/dev/null 2>&1; then
      echo "Dynamo DB table '$table_name' already exists."
      return
    fi

    echo "Dynamo DB table '$table_name' does not exist."
    aws dynamodb create-table --table-name "$table_name" \
      --attribute-definitions '[{"AttributeName":"LockID","AttributeType": "S"}]' \
      --key-schema '[{"AttributeName":"LockID","KeyType": "HASH"}]' \
      --billing-mode PAY_PER_REQUEST >/dev/null
  )
}

terraform_wrapper() {
  terraform -chdir="$terraform_dir" "$@" -no-color
}

new_terraform_workspace() {
  if terraform_wrapper workspace list 2>&1 | grep "$TERRAFORM_WORKSPACE" >/dev/null; then
    echo "Terraform Workspace '$TERRAFORM_WORKSPACE' already exists."
    return
  fi
  echo "Terraform Workspace '$TERRAFORM_WORKSPACE' does not exist."
  terraform_wrapper workspace new "$TERRAFORM_WORKSPACE"
}

init() {
  make_bucket
  create_table

  rm -Rf "$terraform_dir"/.terraform
  terraform_wrapper init -backend-config="bucket=$(fetch_backend_bucket_name)"
  new_terraform_workspace
  terraform_wrapper workspace select "$TERRAFORM_WORKSPACE"
}

run() {
  init
  (
    lock_timeout_seconds="3600s"
    if $TERRAFORM_SHOULD_APPLY; then
      terraform_wrapper apply -lock-timeout=$lock_timeout_seconds -auto-approve
    fi
    terraform_wrapper plan -lock-timeout=$lock_timeout_seconds
  )
}

env() {
  aws_region="terraform_wrapper output aws_region"
  aws_cognito_user_pool_id="terraform_wrapper output aws_cognito_user_pool_id"
  aws_cognito_user_pool_client_id="terraform_wrapper output aws_cognito_user_pool_client_id"
  aws_cognito_user_pool_domain="terraform_wrapper output aws_cognito_user_pool_domain"
  
  {
    echo "REGION=$aws_region"
    echo "USER_POOL_ID=$aws_cognito_user_pool_id"
    echo "USER_POOL_APP_ID=$aws_cognito_user_pool_client_id"
    echo "USER_POOL_DOMAIN=$aws_cognito_user_pool_domain"
  } > back/edge/.env
}

main() {
  if [ "$#" = 0 ]; then
    return
  elif [ "$1" = "init" ]; then
    init
  elif [ "$1" = "run" ]; then
    run
  elif [ "$1" = "env" ]; then
    env
  elif [ "$1" = "check-format" ]; then
    terraform_wrapper fmt -check -recursive -diff
  fi
}

main "$@"
