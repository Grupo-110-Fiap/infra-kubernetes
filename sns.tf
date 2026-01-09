resource "aws_sns_topic" "order_upsert" {
  name = "order-upsert-events-${var.environment}"

  tags = {
    Project     = "TechChallenge"
    Environment = var.environment
  }
}
