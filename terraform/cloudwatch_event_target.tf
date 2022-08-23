resource "aws_s3_bucket" "batch_job_trigger" {
  bucket = "batch-job-trigger-in-${terraform.workspace}"
}

resource "aws_s3_bucket_acl" "batch_job_trigger" {
  bucket = aws_s3_bucket.batch_job_trigger.id
  acl    = "private"
}

resource "aws_s3_bucket_notification" "batch_job_trigger" {
  bucket      = aws_s3_bucket.batch_job_trigger.id
  eventbridge = true
}

resource "aws_cloudwatch_event_rule" "s3_object_was_created" {
  name = "s3-object-was-created"
  event_pattern = jsonencode({
    source : [
      "aws.s3"
    ],
    detail-type : [
      "Object Created"
    ],
    detail : {
      bucket : {
        name : [
          aws_s3_bucket.batch_job_trigger.id
        ]
      }
    }
  })
}

data "aws_iam_policy_document" "events_service" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "events_service" {
  assume_role_policy = data.aws_iam_policy_document.events_service.json
}

data "aws_iam_policy_document" "submitting_batch_job" {
  statement {
    effect = "Allow"
    actions = [
      "batch:SubmitJob"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "submitting_batch_job" {
  policy = data.aws_iam_policy_document.submitting_batch_job.json
}

resource "aws_iam_role_policy_attachment" "attaching_submitting_batch_job_to_events_service" {
  role       = aws_iam_role.events_service.name
  policy_arn = aws_iam_policy.submitting_batch_job.arn
}

resource "aws_cloudwatch_event_target" "invoking_batch_job" {
  rule     = aws_cloudwatch_event_rule.s3_object_was_created.name
  arn      = aws_batch_job_queue.test_batch_job_queue.arn
  role_arn = aws_iam_role.events_service.arn

  batch_target {
    job_definition = aws_batch_job_definition.test_job.arn
    job_name       = aws_batch_job_definition.test_job.name
  }

  input_transformer {
    input_paths = {
      S3BucketValue = "$.detail.bucket.name",
      S3KeyValue    = "$.detail.object.key",
    }
    input_template = <<EOT
{
 "Parameters" :
  {
   "S3bucket": <S3BucketValue>,
   "S3key": <S3KeyValue>
  }
}
EOT
  }
}
