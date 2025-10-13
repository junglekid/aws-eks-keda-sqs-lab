module "sqs" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "~> 5.0"

  name = "${local.sqs_name}-queue"

  create_dlq = true
  redrive_policy = {
    # default is 5 for this module
    maxReceiveCount = 10
  }
}

# IAM policy document for SQS access
data "aws_iam_policy_document" "sqs_access" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl"
    ]
    resources = [
      module.sqs.queue_arn,
      module.sqs.dead_letter_queue_arn
    ]
  }
}

data "aws_iam_policy_document" "sqs_keda_access" {
  statement {
    effect = "Allow"
    sid    = "SQS"
    actions = [
      "sqs:GetQueueAttributes"
    ]
    resources = [
      module.sqs.queue_arn,
      module.sqs.dead_letter_queue_arn
    ]
  }
}
