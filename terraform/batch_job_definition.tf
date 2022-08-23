data "aws_iam_policy_document" "batch_job" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"
      identifiers = [
        "ecs-tasks.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "batch_job" {
  assume_role_policy = data.aws_iam_policy_document.batch_job.json
}

resource "aws_iam_role_policy_attachment" "attaching_ecs_task_execution_role_policy_to_batch_job" {
  role       = aws_iam_role.batch_job.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_batch_job_definition" "test_job" {
  name = "test_job"
  type = "container"
  platform_capabilities = [
    "FARGATE",
  ]

  container_properties = jsonencode({
    command : [
      "echo",
      "Ref::S3bucket",
      "Ref::S3key"
    ],
    image : "busybox",
    fargatePlatformConfiguration : {
      platformVersion : "LATEST"
    },
    resourceRequirements : [
      {
        type : "VCPU",
        value : "0.25"
      },
      {
        type : "MEMORY",
        value : "512"
      }
    ],
    executionRoleArn : aws_iam_role.batch_job.arn
  })
}
