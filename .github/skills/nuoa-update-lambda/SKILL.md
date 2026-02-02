---
name: nuoa-update-lambda
description: Rapid Lambda function deployment for Java-based tenant services without full CDK deployment
---

# NUOA Lambda Update Skill

## Description

This skill provides rapid Lambda function deployment for Java-based tenant services without requiring a full CDK deployment. It uploads the JAR file to S3 and updates Lambda functions directly, significantly reducing deployment time during development.

## Use Cases

- Quick testing of Java Lambda changes
- Hotfixes for production issues
- Development iteration without full infrastructure changes
- Selective function updates based on filters
- Batch updates for multiple Lambda functions

## Prerequisites

- AWS CLI configured with appropriate profile
- Maven for building Java projects
- Bash shell environment
- Access to deployment S3 bucket
- Permissions to update Lambda functions

## Configuration

The script automatically determines the deployment bucket from CDK stack exports:
- Export name format: `DeploymentBucket-{stage}-{tenant-id}-2`
- Default stage: `beta`
- Default tenant-id: `pooled`

## Usage

### Update Single Lambda (by query)
```bash
bash .github/skills/nuoa-update-lambda/update_lambda.sh \
  --profile aws-dev \
  --query ActivityManagement
```

### Update with Rebuild
```bash
bash .github/skills/nuoa-update-lambda/update_lambda.sh \
  --profile aws-dev \
  --query ReportManagement \
  --rebuild
```

### Update All Matching Functions
```bash
bash .github/skills/nuoa-update-lambda/update_lambda.sh \
  --profile aws-dev \
  --query Management \
  --all
```

### Update Specific Tenant
```bash
bash .github/skills/nuoa-update-lambda/update_lambda.sh \
  --profile aws-dev \
  --tenant-id tenant-abc-123 \
  --stage prod \
  --query ActivityGet
```

### Custom JAR Path
```bash
bash .github/skills/nuoa-update-lambda/update_lambda.sh \
  --profile aws-dev \
  --jar custom/path/tenantbackend.jar \
  --query EntityManagement
```

## Parameters

- `--profile` (required): AWS CLI profile name
- `--query` (optional): Filter Lambda functions by name/tag
- `--jar` (optional): Custom JAR file path (default: `lambdas/target/tenantbackend.jar`)
- `--tenant-id` (optional): Tenant ID for deployment (default: `pooled`)
- `--stage` (optional): Environment stage (default: `beta`)
- `--rebuild` (optional): Run Maven clean build before deployment
- `--all` (optional): Update all matching functions without prompt

## Workflow

1. **Build** (if --rebuild): Runs `mvn clean package -Dmaven.test.skip`
2. **Bucket Discovery**: Fetches deployment bucket from CloudFormation exports
3. **Function Listing**: Gets all Java Lambda functions with CloudFormation tags
4. **Filtering**: Applies query filter to function tags/names
5. **Selection**: Prompts for selection (unless --all is used)
6. **Upload**: Uploads JAR to S3 with SHA256 hash metadata
7. **Update**: Updates selected Lambda functions with new code

## Smart Upload

The script includes hash-based caching:
- Calculates SHA256 hash of local JAR
- Compares with S3 object metadata
- Skips upload if hashes match
- Saves time on repeated deployments

## Function Filtering

The script automatically:
- Filters to Java runtime functions only
- Excludes custom resource functions (OpenSearchConstruct, Provider, etc.)
- Matches against CloudFormation logical IDs for clarity
- Supports case-insensitive substring matching

## Interactive Selection

When multiple functions match:
```
Available Lambda functions:
1. ActivityManagementGetActivity
2. ActivityManagementListActivities
3. ActivityManagementCreateActivity

Enter the numbers to deploy (comma-separated, or 'all'):
> 1,3
```

## Error Handling

- **Missing Profile**: Exits with usage message
- **Bucket Not Found**: Verifies CDK stack is deployed
- **No Functions Match**: Reports no matches for query
- **Upload Failure**: Reports S3 upload errors
- **Update Failure**: Reports Lambda update errors per function

## Performance Tips

1. Use `--query` to narrow down functions quickly
2. Use `--all` flag for automated workflows
3. Enable `--rebuild` only when code changes exist
4. Hash checking prevents unnecessary S3 uploads
5. Update multiple functions in one run for efficiency

## Security Notes

- Uses AWS credentials from specified profile
- Requires Lambda update permissions
- Requires S3 PutObject permissions
- JAR metadata includes SHA256 for integrity
- AWS_PAGER disabled for non-interactive execution

## Integration with CI/CD

This script is useful for:
- Development and testing workflows
- Hotfix deployments bypassing full pipeline
- Smoke testing before CDK deployment
- Rollback to previous JAR versions

For production deployments, prefer full CDK deployments via CodePipeline.

## Examples

### Update All Activity Functions
```bash
bash .github/skills/nuoa-update-lambda/update_lambda.sh \
  --profile aws-beta \
  --query Activity \
  --all
```

### Update Single Function with Rebuild
```bash
bash .github/skills/nuoa-update-lambda/update_lambda.sh \
  --profile aws-beta \
  --query ReportManagementGetReport \
  --rebuild
```

### Production Hotfix
```bash
bash .github/skills/nuoa-update-lambda/update_lambda.sh \
  --profile aws-prod \
  --stage prod \
  --tenant-id pooled \
  --query EntityGet \
  --all
```

## Troubleshooting

### "Could not find deployment bucket"
- Ensure CDK stack is deployed for the stage/tenant
- Verify --stage and --tenant-id parameters match deployed stack
- Check export name format: `DeploymentBucket-{stage}-{tenant-id}-2`

### "No Lambda functions found"
- Check AWS profile has correct permissions
- Verify functions exist in the account/region
- Check query filter isn't too restrictive
- Ensure functions are Java runtime (not Python/Node.js)

### "Permission denied" errors
- Verify AWS credentials are valid
- Check IAM permissions for Lambda:UpdateFunctionCode
- Ensure S3 bucket access permissions

### Maven build failures
- Check Java version (requires Java 11)
- Verify Maven is installed and in PATH (requires Maven 3.x.x)
- Check pom.xml for errors
- Review Maven output for dependency issues
- See: [nuoa-tenant-maven skill](../nuoa-tenant-maven/SKILL.md) for detailed build instructions

## Related Skills

- `nuoa-tenant-maven`: Maven build management for tenant services
- `nuoa-call-tenant`: Test API endpoints after deployment
- `deployment-pipeline-design`: Full CI/CD pipeline design
- `aws-solution-architect`: AWS architecture patterns
- `safe-refactoring`: Safe code refactoring practices
