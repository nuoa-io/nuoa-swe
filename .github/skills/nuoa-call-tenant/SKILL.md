---
name: nuoa-call-tenant
description: Call tenant api to test if the api works as expected or not
---
# NUOA Tenant API Call Skill

## Description

This skill enables authenticated API calls to NUOA tenant services using AWS Cognito authentication. It handles the complete authentication flow including tenant initialization, Cognito SRP authentication, and API requests with proper JWT tokens.

## Use Cases

- Testing tenant API endpoints during development
- Validating API responses for specific tenants
- Debugging authentication issues
- Running automated API health checks
- Performing data queries against tenant services

## Prerequisites

- Python 3.9+ with required packages (boto3, requests, pycognito, python-dotenv)
- `.env` file with tenant credentials
- Access to AWS Cognito user pools
- Valid tenant name and user credentials

## Environment Variables

Create a `.env` file with:
```env
ADMIN_BASE_URL=https://admin.beta.nuoa.io
TENANT_NAME=your-tenant-name
USER_EMAIL=user@example.com
USER_PASSWORD=your-password
```

## Usage

### Basic GET Request
```bash
python .github/skills/nuoa-call-tenant/call_api.py \
  --path /reports \
  --method GET
```

### POST Request with Payload
```bash
python .github/skills/nuoa-call-tenant/call_api.py \
  --path /activity \
  --method POST \
  --payload '{"name":"Test Activity","type":"energy"}'
```

### With Custom Headers
```bash
python .github/skills/nuoa-call-tenant/call_api.py \
  --path /reports \
  --method GET \
  --header "X-Custom-Header: value" \
  --origin "https://custom-origin.com"
```

## Parameters

- `--path` (required): API endpoint path (e.g., `/reports`, `/activity`)
- `--method` (optional): HTTP method (default: GET)
- `--payload` (optional): JSON payload for POST/PUT requests
- `--header` (optional): Additional headers (can be used multiple times)
- `--origin` (optional): Origin header value (default: `https://app.beta.nuoa.io`)

## Authentication Flow

1. **Tenant Initialization**: Calls `/tenant/init/{tenant_name}` to get:
   - API Gateway URL
   - Cognito App Client ID
   - Tenant ID
   - User Pool ID

2. **Username Generation**: Creates username as `{tenant_id}.{uuid3(tenant_id + email)}`

3. **Cognito SRP Authentication**: Uses `pycognito` library for secure password authentication

4. **API Call**: Makes authenticated request with JWT Bearer token

## Output

The script outputs the API response as JSON to stdout. Authentication logs and errors are written to stderr.

## Error Handling

- Missing environment variables: Exits with error message
- Invalid JSON payload: Reports parsing error
- Authentication failures: Reports Cognito errors
- API errors: Reports HTTP status and error message

## Security Notes

- Store credentials in `.env` file (never commit to git)
- Use environment-specific `.env` files for different stages
- JWT tokens are automatically refreshed via Cognito
- All API calls use HTTPS

## Integration with Agents

Agents can use this skill to:
1. Verify API functionality after deployments
2. Test data retrieval for specific tenants
3. Validate authentication configurations
4. Generate test data via API calls
5. Debug tenant-specific issues

## Examples

### Get All Reports
```bash
python .github/skills/nuoa-call-tenant/call_api.py \
  --path /reports \
  --method GET
```

### Create New Activity
```bash
python .github/skills/nuoa-call-tenant/call_api.py \
  --path /activity \
  --method POST \
  --payload '{"activityName":"Office Electricity","category":"energy"}'
```

### Get Specific Report
```bash
python .github/skills/nuoa-call-tenant/call_api.py \
  --path /reports/abc123 \
  --method GET
```

## Troubleshooting

### "Missing required environment variables"
- Ensure `.env` file exists and contains all required variables
- Check file is in the correct directory

### "Failed to initialize tenant"
- Verify ADMIN_BASE_URL is correct
- Check tenant name exists
- Ensure network connectivity

### "Authentication failed"
- Verify user credentials are correct
- Check user exists in tenant's Cognito pool
- Ensure user is confirmed (not in pending state)

### "API call failed"
- Check API path is correct
- Verify user has permissions for the endpoint
- Review CloudWatch logs for Lambda errors

## Related Skills

- `nuoa-update-lambda`: Deploy Lambda code changes
- `nuoa-reindex`: Reindex DynamoDB tables
- `testing`: General testing strategies
- `api-contract-design`: API design patterns
