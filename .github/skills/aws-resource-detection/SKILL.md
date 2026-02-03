# AWS Resource Detection Skill

## Overview

Python script using boto3 to detect and list AWS resources across multiple services including Lambda, S3, DynamoDB, CloudFormation, and API Gateway.

## Quick Start

```bash
# 1. Setup (first time only)
bash .github/skills/aws-resource-detection/setup_and_test.sh

# 2. Activate virtual environment
source venv/bin/activate

# 3. Detect resources
python .github/skills/aws-resource-detection/detect_aws_resources.py --profile nuoa --region ap-southeast-1

# 4. Deactivate when done
deactivate
```

## Common Commands

### List All Resources
```bash
python .github/skills/aws-resource-detection/detect_aws_resources.py --profile nuoa --region ap-southeast-1
```

### List Specific Services
```bash
# Lambda functions
python .github/skills/aws-resource-detection/detect_aws_resources.py --profile nuoa --region ap-southeast-1 --service lambda

# S3 buckets
python .github/skills/aws-resource-detection/detect_aws_resources.py --profile nuoa --region ap-southeast-1 --service s3

# DynamoDB tables
python .github/skills/aws-resource-detection/detect_aws_resources.py --profile nuoa --region ap-southeast-1 --service dynamodb

# CloudFormation stacks
python .github/skills/aws-resource-detection/detect_aws_resources.py --profile nuoa --region ap-southeast-1 --service cloudformation

# API Gateways
python .github/skills/aws-resource-detection/detect_aws_resources.py --profile nuoa --region ap-southeast-1 --service apigateway
```

### Get Help
```bash
python .github/skills/aws-resource-detection/detect_aws_resources.py --help
```

## Supported AWS Services

| Service | Information Collected |
|---------|---------------------|
| Lambda | Function name, runtime, ARN, last modified |
| S3 | Bucket name, creation date |
| DynamoDB | Table name, status, item count, size |
| CloudFormation | Stack name, status, creation time |
| API Gateway | API name, ID, creation date |

## Configuration

Default settings in `.env.example`:
- **AWS_PROFILE**: `nuoa`
- **AWS_REGION**: `ap-southeast-1`

## Testing

```bash
# Activate venv
source venv/bin/activate

# Run unit tests
python .github/skills/aws-resource-detection/test_detect_resources.py

# Or run demo
bash .github/skills/aws-resource-detection/demo.sh
```

## Requirements

- Python 3.7+
- AWS credentials configured
- boto3, botocore
- pytest, moto (for testing)

## Example Output

```
================================================================================
AWS Resources in Region: ap-southeast-1
================================================================================

LAMBDA FUNCTIONS (50 found):
--------------------------------------------------------------------------------

  1. GetTenantConfig
     runtime: python3.13
     arn: arn:aws:lambda:ap-southeast-1:070888215368:function:GetTenantConfig
     last_modified: 2026-01-15T02:43:44.000+0000

S3 BUCKETS (19 found):
--------------------------------------------------------------------------------

  1. admin-nuoa-frontend-bucket-beta-070888215368
     creation_date: 2025-11-07T05:03:07+00:00

DYNAMODB TABLES (22 found):
--------------------------------------------------------------------------------

  1. ActivityTable-pooled-beta
     status: ACTIVE
     item_count: 2797
     size_bytes: 1946492
```

## Troubleshooting

### No AWS credentials found
```bash
aws configure --profile nuoa
```

### Token expired (SSO)
```bash
aws sso login --profile nuoa
```

### Profile not found
```bash
aws configure list-profiles
```
