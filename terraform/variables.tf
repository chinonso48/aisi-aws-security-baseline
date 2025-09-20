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

variable "security_account_id" {
  description = "AWS Account ID of the Security account"
  type        = string
  validation {
    condition     = length(var.security_account_id) == 12
    error_message = "Security account ID must be 12 digits."
  }
}

variable "logging_account_id" {
  description = "AWS Account ID of the Logging account"
  type        = string
  validation {
    condition     = length(var.logging_account_id) == 12
    error_message = "Logging account ID must be 12 digits."
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

variable "approved_regions" {
  description = "List of approved AWS regions"
  type        = list(string)
  default     = ["eu-west-2", "eu-west-1", "us-east-1"]
}

variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 90
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention must be a valid CloudWatch retention period."
  }
}

variable "kms_deletion_window" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 30
  validation {
    condition     = var.kms_deletion_window >= 7 && var.kms_deletion_window <= 30
    error_message = "KMS deletion window must be between 7 and 30 days."
  }
}

variable "guardduty_finding_frequency" {
  description = "GuardDuty finding publishing frequency"
  type        = string
  default     = "FIFTEEN_MINUTES"
  validation {
    condition     = contains(["FIFTEEN_MINUTES", "ONE_HOUR", "SIX_HOURS"], var.guardduty_finding_frequency)
    error_message = "GuardDuty frequency must be FIFTEEN_MINUTES, ONE_HOUR, or SIX_HOURS."
  }
}

variable "enable_auto_tagging" {
  description = "Enable automatic tagging of resources"
  type        = bool
  default     = false
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Baseline  = "aisi-security"
  }
}
