resource "aws_security_group" "compute_environment" {
  vpc_id = module.vpc.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_iam_policy_document" "batch_service" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = [
        "batch.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "batch_service" {
  assume_role_policy = data.aws_iam_policy_document.batch_service.json
}

resource "aws_iam_role_policy_attachment" "attaching_aws_batch_service_role_to_batch_service" {
  role       = aws_iam_role.batch_service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

resource "aws_batch_compute_environment" "sample" {
  compute_environment_name = "sample"

  compute_resources {
    max_vcpus = 16
    subnets   = module.vpc.private_subnets
    security_group_ids = [
      aws_security_group.compute_environment.id
    ]
    type = "FARGATE"
  }

  service_role = aws_iam_role.batch_service.arn
  type         = "MANAGED"
  depends_on = [
    aws_iam_role_policy_attachment.attaching_aws_batch_service_role_to_batch_service
  ]
}

resource "aws_batch_job_queue" "test_batch_job_queue" {
  name     = "test-batch-job-queue"
  state    = "ENABLED"
  priority = 1
  compute_environments = [
    aws_batch_compute_environment.sample.arn
  ]
}
