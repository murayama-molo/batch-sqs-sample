module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "batch-sqs-sample-vpc-${terraform.workspace}"
  cidr = "172.31.0.0/16"

  azs              = ["ap-northeast-1a", "ap-northeast-1c"]
  private_subnets  = ["172.31.38.0/24", "172.31.39.0/24"]
  public_subnets   = ["172.31.28.0/24", "172.31.29.0/24"]
  database_subnets = ["172.31.48.0/24", "172.31.49.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    workspace = terraform.workspace
  }
}
