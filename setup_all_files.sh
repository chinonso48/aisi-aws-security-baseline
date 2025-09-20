#!/bin/bash
echo "🚀 Populating AISI AWS Security Baseline files..."

# ===== TERRAFORM FILES =====

# terraform/versions.tf
cat > terraform/versions.tf << 'VERSIONS_EOF'
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = var.default_tags
  }
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-west-2"
}
VERSIONS_EOF

# terraform/variables.tf
cat > terraform/variables.tf << 'VARIABLES_EOF'
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
}

variable "kms_deletion_window" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 30
}

variable "guardduty_finding_frequency" {
  description = "GuardDuty finding publishing frequency"
  type        = string
  default     = "FIFTEEN_MINUTES"
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

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-west-2"
}
VARIABLES_EOF

# terraform/outputs.tf
cat > terraform/outputs.tf << 'OUTPUTS_EOF'
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
OUTPUTS_EOF

# terraform/terraform.tfvars.example
cat > terraform/terraform.tfvars.example << 'TFVARS_EOF'
account_name          = "aisi-ml-platform"
environment          = "prod" 
security_account_id  = "123456789012"
logging_account_id   = "234567890123"
central_logging_bucket = "aisi-org-cloudtrail-logs"
config_s3_bucket     = "aisi-org-config"
approved_regions     = ["eu-west-2", "eu-west-1", "us-east-1"]
log_retention_days   = 90
enable_auto_tagging  = true

default_tags = {
  Organization = "AISI"
  ManagedBy   = "terraform"
  Baseline    = "aisi-security-v1"
  Purpose     = "ml-platform"
  Owner       = "platform-team"
  Project     = "ai-safety-research"
  CostCenter  = "research-ops"
}
TFVARS_EOF

echo "✅ Basic Terraform files created"

# ===== LAMBDA FILES =====

# lambda/exception-manager/requirements.txt
cat > lambda/exception-manager/requirements.txt << 'REQ_EOF'
boto3>=1.26.0
botocore>=1.29.0
REQ_EOF

# lambda/auto-tagger/requirements.txt
cat > lambda/auto-tagger/requirements.txt << 'REQ2_EOF'
boto3>=1.26.0
botocore>=1.29.0
REQ2_EOF

echo "✅ Lambda requirements files created"

# ===== TEST FILES =====

# tests/go.mod
cat > tests/go.mod << 'GOMOD_EOF'
module aisi-security-baseline-tests

go 1.19

require (
    github.com/aws/aws-sdk-go v1.44.0
    github.com/stretchr/testify v1.8.0
)
GOMOD_EOF

echo "✅ Go module files created"

# ===== POLICIES =====

# policies/service-control-policies.json
cat > policies/service-control-policies.json << 'SCP_EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyCloudTrailDisable",
      "Effect": "Deny",
      "Action": [
        "cloudtrail:StopLogging",
        "cloudtrail:DeleteTrail"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:userid": [
            "AIDACKCEVSQ6C2EXAMPLE:break-glass-user"
          ]
        }
      }
    },
    {
      "Sid": "DenyPublicS3",
      "Effect": "Deny",
      "Action": [
        "s3:PutBucketAcl",
        "s3:PutBucketPolicy",
        "s3:PutObjectAcl",
        "s3:DeleteBucketPolicy"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": [
            "public-read",
            "public-read-write",
            "authenticated-read"
          ]
        }
      }
    },
    {
      "Sid": "RequireEncryptionOnCreate",
      "Effect": "Deny",
      "Action": [
        "s3:CreateBucket",
        "rds:CreateDBInstance",
        "rds:CreateDBCluster",
        "dynamodb:CreateTable",
        "sqs:CreateQueue",
        "sns:CreateTopic"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "s3:x-amz-server-side-encryption": ["AES256", "aws:kms"],
          "rds:db-instance-encrypted": "true",
          "dynamodb:sse": "true"
        }
      }
    },
    {
      "Sid": "RestrictRegions",
      "Effect": "Deny",
      "NotAction": [
        "iam:*",
        "sts:*",
        "cloudfront:*",
        "route53:*",
        "support:*"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": [
            "eu-west-2",
            "eu-west-1", 
            "us-east-1"
          ]
        }
      }
    },
    {
      "Sid": "ProtectKMSKeys",
      "Effect": "Deny",
      "Action": [
        "kms:ScheduleKeyDeletion",
        "kms:DeleteAlias"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "kms:AliasName": [
            "alias/*-logging",
            "alias/*-security*"
          ]
        }
      }
    }
  ]
}
SCP_EOF

echo "✅ Service Control Policies created"

# ===== README =====

cat > README.md << 'README_EOF'
# 🛡️ AISI AWS Security Baseline

> **Production-ready AWS security baseline for high-risk AI platforms**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Terraform](https://img.shields.io/badge/Terraform-1.0+-blue.svg)](https://www.terraform.io/)
[![AWS Provider](https://img.shields.io/badge/AWS%20Provider-5.0+-orange.svg)](https://registry.terraform.io/providers/hashicorp/aws/latest)

## 🎯 Overview

The AISI AWS Security Baseline provides comprehensive day-one security controls for new AWS accounts within AISI's multi-account organization. Designed specifically for high-risk AI research platforms, it implements defense-in-depth security with automated compliance monitoring and intelligent exception management.

### ⚡ Quick Start
```bash

# Press Ctrl+C to exit the heredoc, then run:

# Create a simple script to populate all files
cat > populate_files.sh << 'EOF'
#!/bin/bash
echo "🚀 Creating AISI Security Baseline files..."

# Create README.md
cat > README.md << 'README_END'
# 🛡️ AISI AWS Security Baseline

> **Production-ready AWS security baseline for high-risk AI platforms**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Terraform](https://img.shields.io/badge/Terraform-1.0+-blue.svg)](https://www.terraform.io/)

## 🎯 Overview

The AISI AWS Security Baseline provides comprehensive day-one security controls for new AWS accounts within AISI's multi-account organization. Designed specifically for high-risk AI research platforms.

### ⚡ Quick Start
```bash
git clone https://github.com/chinonso48/aisi-aws-security-baseline.git
cd aisi-aws-security-baseline
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars with your account details
./scripts/deploy.sh
# Create README.md
cat > README.md << 'EOF'
# 🛡️ AISI AWS Security Baseline

> **Production-ready AWS security baseline for high-risk AI platforms**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Terraform](https://img.shields.io/badge/Terraform-1.0+-blue.svg)](https://www.terraform.io/)

## 🎯 Overview

The AISI AWS Security Baseline provides comprehensive day-one security controls for new AWS accounts within AISI's multi-account organization. Designed specifically for high-risk AI research platforms.

### ⚡ Quick Start
```bash
git clone https://github.com/chinonso48/aisi-aws-security-baseline.git
cd aisi-aws-security-baseline
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars with your account details
./scripts/deploy.sh
clear
