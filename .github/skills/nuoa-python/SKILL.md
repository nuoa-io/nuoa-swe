---
name: nuoa-python
description: Best practices, patterns, and conventions for Python development in NUOA's CDK infrastructure, Lambda handlers, and scripts
---

# NUOA Python Development Skill

## Description

This skill defines best practices, patterns, and conventions for Python development in NUOA's infrastructure code (CDK), Lambda handlers, and utility scripts. It covers both Python 3.12 Lambda handlers and Python-based CDK constructs.

## Language Versions

- **Lambda Runtime**: Python 3.12
- **CDK/Scripts**: Python 3.9+ (for broader compatibility)
- **Development**: Python 3.12 recommended

## Project Structure

### Lambda Handlers

```
src/python/lambdas/
├── activity/
│   ├── __init__.py
│   ├── handler.py
│   ├── repository.py
│   └── models.py
├── report/
│   ├── __init__.py
│   └── handler.py
└── common/
    ├── __init__.py
    ├── exceptions.py
    └── utils.py
```

### Scripts

```
src/python/scripts/
├── call_api.py
├── increase_version_of_table.py
└── data_migration.py
```

## Lambda Handler Pattern

### Standard Handler Structure

```python
"""
Activity GET Lambda handler.
Retrieves activity details for a tenant.
"""
import json
import os
import logging
from typing import Dict, Any, Optional
import boto3
from botocore.exceptions import ClientError

# Initialize outside handler for connection reuse
dynamodb = boto3.resource('dynamodb')
table_name = os.environ['ACTIVITY_TABLE_NAME']
table = dynamodb.Table(table_name)

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event: Dict[str, Any], context) -> Dict[str, Any]:
    """
    Lambda handler for GET /activities/{id}
    
    Args:
        event: API Gateway proxy event
        context: Lambda context
        
    Returns:
        API Gateway proxy response
    """
    try:
        # 1. Extract parameters
        tenant_id = event['requestContext']['authorizer']['claims']['custom:tenantId']
        activity_id = event['pathParameters']['id']
        
        # 2. Validate input
        if not activity_id:
            return build_error_response(400, "Missing activity ID")
        
        # 3. Execute business logic
        activity = get_activity(tenant_id, activity_id)
        
        if not activity:
            return build_error_response(404, "Activity not found")
        
        # 4. Return success response
        return build_success_response(activity)
        
    except ClientError as e:
        logger.error(f"DynamoDB error: {e.response['Error']['Message']}")
        return build_error_response(500, "Database error")
    except Exception as e:
        logger.exception("Unexpected error")
        return build_error_response(500, "Internal server error")

def get_activity(tenant_id: str, activity_id: str) -> Optional[Dict[str, Any]]:
    """
    Retrieve activity from DynamoDB.
    
    Args:
        tenant_id: Tenant identifier
        activity_id: Activity identifier
        
    Returns:
        Activity data or None if not found
    """
    response = table.get_item(
        Key={
            'tenantId': tenant_id,
            'activityId': activity_id
        }
    )
    return response.get('Item')

def build_success_response(body: Any) -> Dict[str, Any]:
    """Build successful API Gateway response."""
    return {
        'statusCode': 200,
        'headers': get_cors_headers(),
        'body': json.dumps(body, default=str)
    }

def build_error_response(status_code: int, message: str) -> Dict[str, Any]:
    """Build error API Gateway response."""
    return {
        'statusCode': status_code,
        'headers': get_cors_headers(),
        'body': json.dumps({'error': message})
    }

def get_cors_headers() -> Dict[str, str]:
    """Get CORS headers for API responses."""
    return {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
    }
```

## Type Hints

Always use type hints for better code clarity and IDE support:

```python
from typing import Dict, List, Optional, Any, Tuple, Union
from datetime import datetime
from decimal import Decimal

def process_activities(
    tenant_id: str,
    activity_ids: List[str],
    filters: Optional[Dict[str, Any]] = None
) -> Tuple[List[Dict[str, Any]], int]:
    """
    Process activities with optional filters.
    
    Args:
        tenant_id: Tenant identifier
        activity_ids: List of activity IDs to process
        filters: Optional filtering criteria
        
    Returns:
        Tuple of (processed activities, total count)
    """
    # Implementation
    pass

def calculate_total(amount: Union[int, float, Decimal]) -> Decimal:
    """Convert various number types to Decimal for precision."""
    return Decimal(str(amount))
```

## DynamoDB Best Practices

### Query vs Scan

```python
# Good: Use query with partition key
response = table.query(
    KeyConditionExpression=Key('tenantId').eq(tenant_id)
)

# Good: Query with sort key condition
response = table.query(
    KeyConditionExpression=Key('tenantId').eq(tenant_id) & Key('activityId').begins_with('act-')
)

# Avoid: Full table scan (expensive)
response = table.scan()  # Only use when absolutely necessary
```

### Batch Operations

```python
# Batch get
from boto3.dynamodb.conditions import Key

response = dynamodb.batch_get_item(
    RequestItems={
        table_name: {
            'Keys': [
                {'tenantId': tenant_id, 'activityId': aid} 
                for aid in activity_ids
            ]
        }
    }
)

# Batch write
with table.batch_writer() as batch:
    for item in items:
        batch.put_item(Item=item)
```

### Optimistic Locking

```python
def update_with_version_check(tenant_id: str, activity_id: str, updates: Dict[str, Any], current_version: int):
    """Update item with optimistic locking."""
    try:
        response = table.update_item(
            Key={
                'tenantId': tenant_id,
                'activityId': activity_id
            },
            UpdateExpression='SET #name = :name, versionId = :new_version',
            ConditionExpression='versionId = :current_version',
            ExpressionAttributeNames={
                '#name': 'name'
            },
            ExpressionAttributeValues={
                ':name': updates['name'],
                ':current_version': current_version,
                ':new_version': current_version + 1
            },
            ReturnValues='ALL_NEW'
        )
        return response['Attributes']
    except ClientError as e:
        if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
            raise ConflictException("Item was modified by another process")
        raise
```

## Error Handling

### Custom Exceptions

```python
class NuoaException(Exception):
    """Base exception for NUOA errors."""
    def __init__(self, status_code: int, message: str):
        self.status_code = status_code
        self.message = message
        super().__init__(self.message)

class NotFoundException(NuoaException):
    """Resource not found error."""
    def __init__(self, message: str = "Resource not found"):
        super().__init__(404, message)

class ValidationException(NuoaException):
    """Input validation error."""
    def __init__(self, message: str):
        super().__init__(400, message)

class ConflictException(NuoaException):
    """Resource conflict error."""
    def __init__(self, message: str = "Resource conflict"):
        super().__init__(409, message)
```

### Exception Handler Decorator

```python
from functools import wraps

def handle_exceptions(func):
    """Decorator to handle common Lambda exceptions."""
    @wraps(func)
    def wrapper(event, context):
        try:
            return func(event, context)
        except NotFoundException as e:
            return build_error_response(e.status_code, e.message)
        except ValidationException as e:
            return build_error_response(e.status_code, e.message)
        except ClientError as e:
            logger.error(f"AWS error: {e.response['Error']}")
            return build_error_response(500, "Service error")
        except Exception as e:
            logger.exception("Unexpected error")
            return build_error_response(500, "Internal server error")
    return wrapper

@handle_exceptions
def lambda_handler(event, context):
    # Handler logic
    pass
```

## Environment Variables

```python
import os
from typing import Optional

def get_env_var(key: str, default: Optional[str] = None) -> str:
    """
    Get environment variable with optional default.
    Raises ValueError if not found and no default provided.
    """
    value = os.environ.get(key, default)
    if value is None:
        raise ValueError(f"Missing required environment variable: {key}")
    return value

# Usage
TABLE_NAME = get_env_var('ACTIVITY_TABLE_NAME')
STAGE = get_env_var('STAGE', 'dev')
DEBUG_MODE = get_env_var('DEBUG', 'false').lower() == 'true'
```

## Logging

```python
import logging
import json

# Configure structured logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def log_event(action: str, **kwargs):
    """Log structured event for CloudWatch Insights."""
    log_data = {
        'action': action,
        **kwargs
    }
    logger.info(json.dumps(log_data))

# Usage
log_event('get_activity', tenant_id=tenant_id, activity_id=activity_id, duration_ms=125)

# Output: {"action": "get_activity", "tenant_id": "tenant-123", "activity_id": "act-456", "duration_ms": 125}
```

## Data Validation

### Pydantic Models

```python
from pydantic import BaseModel, Field, validator
from typing import Optional
from datetime import datetime

class ActivityCreate(BaseModel):
    """Model for creating activity."""
    name: str = Field(..., min_length=1, max_length=200)
    type: str = Field(..., regex='^(energy|water|waste|transport)$')
    description: Optional[str] = Field(None, max_length=1000)
    
    @validator('name')
    def name_must_not_be_empty(cls, v):
        if not v.strip():
            raise ValueError('Name cannot be empty or whitespace')
        return v.strip()

# Usage in handler
def lambda_handler(event, context):
    try:
        body = json.loads(event['body'])
        activity_data = ActivityCreate(**body)
        # activity_data is validated
    except ValidationError as e:
        return build_error_response(400, str(e))
```

## Testing

See [nuoa-testing-python](../nuoa-testing-python/SKILL.md) for comprehensive testing strategies.

## Scripts Best Practices

### Argument Parsing

```python
import argparse
import sys

def main():
    """Main entry point for the script."""
    parser = argparse.ArgumentParser(
        description='Process DynamoDB table operations',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s --table-name ActivityTable --operation scan
  %(prog)s --table-name ReportTable --operation count --tenant-id tenant-123
        """
    )
    
    parser.add_argument('--table-name', required=True, help='DynamoDB table name')
    parser.add_argument('--operation', choices=['scan', 'count', 'update'], default='scan')
    parser.add_argument('--tenant-id', help='Filter by tenant ID')
    parser.add_argument('--dry-run', action='store_true', help='Perform dry run')
    parser.add_argument('--profile', help='AWS profile name')
    
    args = parser.parse_args()
    
    # Validate arguments
    if args.operation == 'update' and not args.tenant_id:
        parser.error("--tenant-id is required for update operation")
    
    # Execute
    try:
        result = process_table(args)
        print(json.dumps(result, indent=2))
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
```

## Code Style

### PEP 8 Compliance

- Line length: 100 characters (not 79 for better readability)
- Indentation: 4 spaces
- Imports: Standard library, third-party, local (separated by blank line)
- Naming:
  - Functions/variables: `snake_case`
  - Classes: `PascalCase`
  - Constants: `UPPER_SNAKE_CASE`
  - Private: `_leading_underscore`

### Docstrings

```python
def complex_calculation(
    input_data: Dict[str, Any],
    options: Optional[Dict[str, Any]] = None
) -> Tuple[float, List[str]]:
    """
    Perform complex calculation with optional configuration.
    
    This function processes the input data according to the specified options
    and returns both a numeric result and a list of warnings.
    
    Args:
        input_data: Dictionary containing calculation parameters.
            Required keys: 'value', 'factor'
            Optional keys: 'adjustment'
        options: Optional configuration dictionary.
            Supported keys: 'precision', 'round_mode'
            
    Returns:
        Tuple containing:
        - float: The calculated result
        - list: List of warning messages (empty if no warnings)
        
    Raises:
        ValueError: If required keys are missing from input_data
        TypeError: If input_data values are not numeric
        
    Example:
        >>> result, warnings = complex_calculation({'value': 10, 'factor': 2.5})
        >>> print(result)
        25.0
    """
    # Implementation
    pass
```

## Common Patterns

### Singleton Pattern for AWS Clients

```python
from typing import Optional
import boto3

class DynamoDBClient:
    """Singleton for DynamoDB client."""
    _instance: Optional['DynamoDBClient'] = None
    _resource = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._resource = boto3.resource('dynamodb')
        return cls._instance
    
    def get_table(self, table_name: str):
        """Get DynamoDB table."""
        return self._resource.Table(table_name)

# Usage
db_client = DynamoDBClient()
table = db_client.get_table('ActivityTable')
```

### Context Manager for Resources

```python
from contextlib import contextmanager
import boto3

@contextmanager
def dynamodb_batch_writer(table_name: str):
    """Context manager for DynamoDB batch writer."""
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(table_name)
    
    with table.batch_writer() as batch:
        try:
            yield batch
        except Exception as e:
            logger.error(f"Batch write error: {e}")
            raise

# Usage
with dynamodb_batch_writer('ActivityTable') as batch:
    for item in items:
        batch.put_item(Item=item)
```

## Dependencies

### requirements.txt

```txt
boto3>=1.34.0
botocore>=1.34.0
pydantic>=2.5.0
python-dotenv>=1.0.0
requests>=2.31.0
```

### Lambda Layer

For shared dependencies, create a Lambda layer:
```bash
mkdir -p python/lib/python3.12/site-packages
pip install -r requirements.txt -t python/lib/python3.12/site-packages
zip -r layer.zip python
```

## Related Skills

- [nuoa-testing-python](../nuoa-testing-python/SKILL.md): Python testing strategies
- [nuoa-call-tenant](../nuoa-call-tenant/SKILL.md): API call script
- [nuoa-reindex](../nuoa-reindex/SKILL.md): DynamoDB reindex script
- [aws-solution-architect](../aws-solution-architect/SKILL.md): AWS best practices
