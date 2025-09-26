# AISI AWS Security Baseline – Submission Report

**Candidate**: Daniel Ogochukwu
**Position**: Principal Platform/Product Security Engineer
**Date**: September 2025
**Challenge**: Securing a New AWS Account

## Executive Summary

This submission delivers a production-ready AWS security baseline for AISI’s high-risk platforms. It establishes strong day-one posture with centralized logging, encryption, tagging enforcement, and SCP guardrails. The design balances security, operational efficiency, and cost, while remaining modular and extensible for future needs.

## Key Controls & Value

* **Centralized Logging**: CloudTrail, VPC Flow Logs, and GuardDuty routed to a dedicated logging account → provides tamper-resistant audit trails and forensic visibility.
* **Encryption (KMS Everywhere)**: Default EBS encryption, S3 SSE, and customer-managed KMS keys for RDS/other services → protects data at rest, reduces breach impact, and ensures compliance.
* **Tagging Enforcement**: Required tags with optional auto-remediation → improves ownership, cost tracking, and consistent governance.
* **SCP Guardrails**: Prevent disabling CloudTrail, block public S3, enforce encryption, and restrict regions → prevents drift and enforces baseline security.

## Assumptions

* AWS Organizations with Security and Logging accounts already exist.
* Central S3 buckets for CloudTrail/Config are pre-provisioned.
* Platform teams have basic AWS/Terraform knowledge and CI/CD pipelines.
* High-risk workloads justify moderate additional cost for security controls.

## Trade-offs & Limitations

* Selected AWS Config for drift detection (broader coverage, higher cost).
* Chose customer-managed KMS keys over AWS-managed (greater control, added complexity).
* SCP unit tests included, but full validation requires Organization-level deployment.

## Adoption & Socialization Plan

* Provide a reference Terraform module with deployment scripts and onboarding documentation.
* Run short workshops with platform teams to walk through setup and usage.
* Integrate dashboards and alerts into existing monitoring/SIEM to demonstrate value.
* Emphasize reduced effort and cost compared to ad-hoc account hardening.

## Conclusion

The baseline secures new AWS accounts from day one, reducing risks of misconfiguration, compliance failure, and insider threats. It is cost-conscious, developer-friendly, and designed to scale across AISI’s multi-account environment while evolving with future security requirements.
