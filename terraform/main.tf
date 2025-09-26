# AWS Security Baseline Module
# Provides day-one security posture for new accounts

# --- Disabled data sources for demo mode ---
# data "aws_caller_identity" "current" {}
# data "aws_region" "current" {}
# data "aws_organizations_organization" "org" {}

# Local values for consistent resource naming (using static demo values)
locals {
  account_id = "123456789012"
  region     = "eu-west-2"

  common_tags = merge(var.default_tags, {
    Environment  = var.environment
    ManagedBy    = "terraform"
    Baseline     = "aisi-security-v1"
    CreatedDate  = "2025-09-26"
  })
}

# ==== CENTRALIZED LOGGING ====

# CloudTrail for API logging
resource "aws_cloudtrail" "main" {
  name                          = "${var.account_name}-cloudtrail"
  s3_bucket_name                = var.central_logging_bucket
  s3_key_prefix                  = "cloudtrail/${local.account_id}/"
  include_global_service_events  = true
  is_multi_region_trail          = true
  enable_logging                 = true
}
