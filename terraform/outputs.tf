output "cloudtrail_arn" {
  description = "ARN of the CloudTrail"
  value       = aws_cloudtrail.main.arn
}

output "logging_kms_key_arn" {
  description = "ARN of the logging KMS key"
  value       = aws_kms_key.logging.arn
}

output "ebs_kms_key_arn" {
  description = "ARN of the EBS KMS key"
  value       = aws_kms_key.ebs.arn
}

output "data_kms_key_arn" {
  description = "ARN of the general data KMS key"
  value       = aws_kms_key.data.arn
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = aws_guardduty_detector.main.id
}

output "config_recorder_name" {
  description = "Name of the Config configuration recorder"
  value       = aws_config_configuration_recorder.main.name
}

output "sns_topic_arn" {
  description = "ARN of the compliance alerts SNS topic"
  value       = aws_sns_topic.compliance_alerts.arn
}

output "exceptions_table_name" {
  description = "Name of the exceptions DynamoDB table"
  value       = aws_dynamodb_table.tagging_exceptions.name
}
