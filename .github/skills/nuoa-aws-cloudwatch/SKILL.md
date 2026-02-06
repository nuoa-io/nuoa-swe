---
name: nuoa-aws-cloudwatch
description: Manage AWS Lambda functions and CloudWatch logs. Use to list lambdas by domain/stage or fetch CloudWatch logs with time filters.
metadata:
  author: nuoa
  version: "1.0.0"
  argument-hint: <command> [options]
---

# NUOA AWS CloudWatch Skill

Interact with AWS Lambda functions and CloudWatch logs for NUOA infrastructure.

## Prerequisites

- AWS credentials configured (via ~/.aws/credentials or environment)
- Python 3.x with boto3 and python-dotenv installed
- Profile name in .env files (e.g., VITE_AWS_ADMIN_URL contains stage info)

## Commands

### 1. get_lambdas
List Lambda functions filtered by domain and stage.

**Usage:** `python .github/skills/nuoa-aws-cloudwatch/get_lambdas.py --domain <domain> --stage <stage> --profile <aws-profile>`

**Options:**
- `--domain`: Domain name (e.g., reportmanagement, activitymanagement)
- `--stage`: Environment stage (beta, prod, gamma)
- `--profile`: AWS profile name (e.g., nuoa, nuoa-beta)

### 2. get_logs
Fetch CloudWatch logs for a Lambda function.

**Usage:** `python .github/skills/nuoa-aws-cloudwatch/get_logs.py --function <name> --time <duration> --profile <aws-profile>`

**Options:**
- `--function`: Lambda function name
- `--time`: Time range (1m, 5m, 10m, 1h, etc.)
- `--profile`: AWS profile name (e.g., nuoa, nuoa-beta)

## Example Workflow

1. List lambdas: `python get_lambdas.py --domain reportmanagement --stage beta --profile nuoa-beta`
2. Get logs: `python get_logs.py --function nuoa-beta-reportmanagement-api --time 5m --profile nuoa-beta`

## Notes

Activate .venv before running: `source .venv/bin/activate`
