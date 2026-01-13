resource "aws_sns_topic" "order_upsert" {
  name = "order-upsert-events-${var.environment}"

  tags = {
    Project     = "TechChallenge"
    Environment = var.environment
  }
}

resource "aws_sqs_queue" "order_upsert_queue" {
  name                       = "order-upsert-queue-${var.environment}"
  visibility_timeout_seconds = 300
  message_retention_seconds  = 1209600 # 14 days
  receive_wait_time_seconds  = 20      # Enable long polling

  tags = {
    Project     = "TechChallenge"
    Environment = var.environment
  }
}

resource "aws_sns_topic_subscription" "order_upsert_sqs" {
  topic_arn = aws_sns_topic.order_upsert.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.order_upsert_queue.arn
}

resource "aws_sqs_queue_policy" "order_upsert_queue_policy" {
  queue_url = aws_sqs_queue.order_upsert_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.order_upsert_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.order_upsert.arn
          }
        }
      }
    ]
  })
}
