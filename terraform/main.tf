# Complete AISI AWS Security Baseline
# This creates all the security controls we designed

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  
  common_tags = merge(var.default_tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Baseline    = "aisi-security-v1"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  })
}

# ==== KMS ENCRYPTION KEYS ====

# Logging KMS Key
resource "aws_kms_key" "logging" {
  description             = "KMS key for logging services"
  deletion_window_in_days = var.kms_deletion_window
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudTrail access"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name    = "logging-key"
    Purpose = "centralized-logging"
  })
}

resource "aws_kms_alias" "logging" {
  name          = "alias/${var.account_name}-logging"
  target_key_id = aws_kms_key.logging.key_id
}

# EBS Encryption Key
resource "aws_kms_key" "ebs" {
  description             = "KMS key for EBS volumes"
  deletion_window_in_days = var.kms_deletion_window
  enable_key_rotation     = true

  tags = merge(local.common_tags, {
    Name    = "ebs-encryption-key"
    Purpose = "ebs-volume-encryption"
  })
}

resource "aws_kms_alias" "ebs" {
  name          = "alias/${var.account_name}-ebs"
  target_key_id = aws_kms_key.ebs.key_id
}

# Data Key for general use
resource "aws_kms_key" "data" {
  description             = "General purpose data encryption key"
  deletion_window_in_days = var.kms_deletion_window
  enable_key_rotation     = true

  tags = merge(local.common_tags, {
    Name    = "data-encryption-key"
    Purpose = "general-data-encryption"
  })
}

resource "aws_kms_alias" "data" {
  name          = "alias/${var.account_name}-data"
  target_key_id = aws_kms_key.data.key_id
}

# ==== CENTRALIZED LOGGING ====

# CloudTrail
resource "aws_cloudtrail" "main" {
  name                          = "${var.account_name}-cloudtrail"
  s3_bucket_name               = var.central_logging_bucket
  s3_key_prefix                = "cloudtrail/${local.account_id}/"
  include_global_service_events = true
  is_multi_region_trail        = true
  enable_logging               = true
  enable_log_file_validation   = true
  kms_key_id                   = aws_kms_key.logging.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::*/*"]
    }
  }

  tags = local.common_tags
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "account_logs" {
  name              = "/aws/account/${var.account_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.logging.arn

  tags = local.common_tags
}

# VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flowlogs"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.logging.arn

  tags = local.common_tags
}

# IAM role for VPC Flow Logs
resource "aws_iam_role" "flow_log" {
  name = "flowlogsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "flow_log" {
  name = "flowlogsDeliveryRolePolicy"
  role = aws_iam_role.flow_log.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# GuardDuty
resource "aws_guardduty_detector" "main" {
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = local.common_tags
}

# ==== EBS ENCRYPTION BY DEFAULT ====

resource "aws_ebs_encryption_by_default" "main" {
  enabled = true
}

resource "aws_ebs_default_kms_key" "main" {
  key_id = aws_kms_key.ebs.arn
}

# ==== S3 SECURITY ====

resource "aws_s3_account_public_access_block" "main" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ==== CONFIG FOR COMPLIANCE ====

resource "aws_iam_role" "config" {
  name = "aws-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/ConfigRole"
}

# Config Delivery Channel
resource "aws_config_delivery_channel" "main" {
  name           = "aisi-config-delivery"
  s3_bucket_name = var.config_s3_bucket
  s3_key_prefix  = "config/${local.account_id}/"
}

# Config Configuration Recorder
resource "aws_config_configuration_recorder" "main" {
  name     = "aisi-config-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }

  depends_on = [aws_config_delivery_channel.main]
}

# Required Tags Rule
resource "aws_config_config_rule" "required_tags" {
  name = "required-tags"

  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }

  input_parameters = jsonencode({
    tag1Key = "Environment"
    tag2Key = "Owner"
    tag3Key = "Project"
    tag4Key = "CostCenter"
  })

  depends_on = [aws_config_configuration_recorder.main]
}

# ==== SNS FOR NOTIFICATIONS ====

resource "aws_sns_topic" "compliance_alerts" {
  name              = "aisi-compliance-alerts"
  kms_master_key_id = aws_kms_key.data.arn

  tags = local.common_tags
}

# ==== EXCEPTION MANAGEMENT (Simplified for demo) ====

resource "aws_dynamodb_table" "tagging_exceptions" {
  name         = "aisi-tagging-exceptions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "resource_arn"

  attribute {
    name = "resource_arn"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.data.arn
  }

  tags = merge(local.common_tags, {
    Name    = "tagging-exceptions"
    Purpose = "track-compliance-exceptions"
  })
}
