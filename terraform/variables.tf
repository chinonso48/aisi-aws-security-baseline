variable "account_name" {
  description = "Name of the AWS account"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "central_logging_bucket" {
  description = "Name of the central S3 bucket for CloudTrail logs"
  type        = string
}

variable "config_s3_bucket" {
  description = "Name of the S3 bucket for AWS Config"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 90
}

variable "kms_deletion_window" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 30
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Baseline  = "aisi-security"
  }
}
