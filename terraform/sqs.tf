module "result_queue" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "~> 2.0"

  name = "result-${terraform.workspace}"

  tags = {
    Environment = terraform.workspace
  }
}