# NUOA AWS CloudWatch Skill

AWS Lambda and CloudWatch logs management scripts for NUOA infrastructure.

## Setup

1. **Create virtual environment** (if not exists):
   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   pip install boto3 python-dotenv
   ```

2. **Configure AWS credentials** in `~/.aws/credentials`:
   ```ini
   [nuoa]
   aws_access_key_id = YOUR_KEY
   aws_secret_access_key = YOUR_SECRET
   
   [nuoa-beta]
   aws_access_key_id = YOUR_KEY
   aws_secret_access_key = YOUR_SECRET
   ```

## Usage

### List Lambda Functions

```bash
source .venv/bin/activate
python .github/skills/nuoa-aws-cloudwatch/get_lambdas.py \
  --domain reportmanagement \
  --stage beta \
  --profile nuoa-beta
```

### Get CloudWatch Logs

```bash
source .venv/bin/activate
python .github/skills/nuoa-aws-cloudwatch/get_logs.py \
  --function nuoa-beta-reportmanagement-api \
  --time 5m \
  --profile nuoa-beta
```

**Time formats**: `1m`, `5m`, `10m`, `30m`, `1h`, `2h`, `1d`

## Examples

```bash
# List all beta lambdas for reportmanagement
python get_lambdas.py --domain reportmanagement --stage beta --profile nuoa-beta

# List all prod lambdas
python get_lambdas.py --stage prod --profile nuoa

# Get last 10 minutes of logs
python get_logs.py --function nuoa-prod-activitymanagement-api --time 10m --profile nuoa
```
