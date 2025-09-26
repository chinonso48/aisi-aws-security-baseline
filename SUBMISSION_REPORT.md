# AISI AWS Security Baseline – Submission Report

**Candidate**: Daniel Ogochukwu
**Position**: Principal Platform/Product Security Engineer
**Date**: September 2025
**Challenge**: Securing a New AWS Account

## Executive Summary

This submission provides a production-ready AWS security baseline for high-risk AISI platforms. It implements centralized logging, encryption, tagging enforcement, and SCP guardrails to establish a strong day-one posture. The design balances security, operational efficiency, and cost, with extensibility for future production needs.

## Key Decisions & Value

* **Centralized Logging**: CloudTrail, VPC Flow Logs, and GuardDuty routed to dedicated logging account → ensures tamper-resistant audit trails and forensic visibility.
* **Encryption (KMS Everywhere)**: Default EBS encryption, S3 SSE, and customer-managed KMS keys for RDS/other services → reduces breach impact, meets compliance.
* **Tagging Enforcement**: Required tags plus auto-remediation options → improves ownership, cost tracking, and compliance alignment.
* **SCP Guardrails**: Prevent disabling CloudTrail, block public S3, enforce encryption, restrict regions → prevents drift and misconfigurations.

## Assumptions

* AWS Organizations with Security and Logging accounts already exist.
* Teams use Terraform/CI pipelines and have basic AWS familiarity.
* Central S3 buckets for CloudTrail/Config already provisioned.
* High-risk workloads justify comprehensive controls despite moderate cost.

## Trade-offs & Limitations

* Chose AWS Config for drift detection (broader coverage, higher cost).
* Used customer KMS keys over AWS-managed (more control, added complexity).
* SCPs tested with unit tests but require Organization-level deployment for full validation.

## Adoption & Socialization Plan

* Provide a reference implementation with scripts and onboarding docs.
* Run workshops with platform teams to walk through deployment.
* Integrate dashboards/alerts into existing monitoring to demonstrate value.
* Highlight cost/effort savings vs. ad-hoc account hardening.

## Conclusion

The baseline establishes strong foundations for AISI’s high-risk platforms, addressing regulatory compliance, insider threat, and configuration drift risks. It is modular, cost-conscious, and designed to evolve with AISI’s security needs.

