terraform {
  required_version = "= 1.2.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 4.22.0"
    }
  }

  backend "s3" {
    bucket         = "batch-sqs-sample"
    region         = "ap-northeast-1"
    key            = "terraform.tfstate"
    dynamodb_table = "batch-sqs-sample-state-locking"
  }
}

provider "aws" {
  region = "ap-northeast-1"
}
