# 🛡️ AISI AWS Security Baseline

> **Production-ready AWS security baseline for high-risk AI platforms**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Terraform](https://img.shields.io/badge/Terraform-1.0+-blue.svg)](https://www.terraform.io/)
[![AWS Provider](https://img.shields.io/badge/AWS%20Provider-5.0+-orange.svg)](https://registry.terraform.io/providers/hashicorp/aws/latest)
[![Tests](https://img.shields.io/badge/Tests-Passing-green.svg)](#testing)

## 🎯 Overview

The AISI AWS Security Baseline provides comprehensive day-one security controls for new AWS accounts within AISI's multi-account organization. Designed specifically for high-risk AI research platforms, it implements defense-in-depth security with automated compliance monitoring and intelligent exception management.

### ⚡ Quick Start
```bash
# Clone and deploy
git clone https://github.com/chinonso48/aisi-aws-security-baseline.git
cd aisi-aws-security-baseline
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars with your account details
./scripts/deploy.sh
