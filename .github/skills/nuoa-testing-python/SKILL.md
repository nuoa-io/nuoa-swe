---
name: nuoa-testing-python
description: Comprehensive testing strategies for Python Lambda handlers, scripts, and CDK constructs with pytest, mocking, and fixtures
---

# NUOA Python Testing Strategy

## Description

This skill defines comprehensive testing strategies for Python Lambda handlers, scripts, and CDK constructs in NUOA's infrastructure. It covers pytest usage, mocking AWS services, fixtures, and test organization.

## Testing Framework

### Core Dependencies

```txt
# Testing
pytest>=7.4.0
pytest-cov>=4.1.0
pytest-mock>=3.12.0
pytest-asyncio>=0.21.0

# AWS Mocking
moto>=4.2.0
boto3-stubs[essential]>=1.34.0

# Assertions and utilities
freezegun>=1.2.0  # Time mocking
responses>=0.23.0  # HTTP mocking
```

## Test Structure

### Package Organization

```
test/python/
├── conftest.py              # Shared fixtures
├── lambdas/
│   ├── __init__.py
│   ├── auth/
│   │   ├── conftest.py      # Auth-specific fixtures
│   │   ├── test_tenant_authorizer.py
│   │   └── test_shared_service_authorizer.py
│   ├── activity/
│   │   ├── conftest.py
│   │   └── test_handler.py
│   └── report/
│       └── test_handler.py
└── scripts/
    ├── test_call_api.py
    └── test_increase_version.py
```

## Unit Testing Patterns

### Lambda Handler Test

```python
"""
Test module for activity GET Lambda handler.
"""
import json
import pytest
from unittest.mock import Mock, patch, MagicMock
from botocore.exceptions import ClientError

from src.python.lambdas.activity import handler


class TestActivityGetHandler:
    """Test cases for activity GET handler."""
    
    def test_should_return_activity_when_found(self, mock_dynamodb_table, sample_activity):
        """Test successful activity retrieval."""
        # Given
        event = {
            'pathParameters': {'id': 'activity-123'},
            'requestContext': {
                'authorizer': {
                    'claims': {'custom:tenantId': 'tenant-123'}
                }
            }
        }
        
        mock_dynamodb_table.get_item.return_value = {
            'Item': sample_activity
        }
        
        # When
        with patch('src.python.lambdas.activity.handler.table', mock_dynamodb_table):
            response = handler.lambda_handler(event, None)
        
        # Then
        assert response['statusCode'] == 200
        body = json.loads(response['body'])
        assert body['activityId'] == 'activity-123'
        assert body['name'] == 'Office Electricity'
        
        # Verify DynamoDB call
        mock_dynamodb_table.get_item.assert_called_once_with(
            Key={
                'tenantId': 'tenant-123',
                'activityId': 'activity-123'
            }
        )
    
    def test_should_return_404_when_activity_not_found(self, mock_dynamodb_table):
        """Test 404 response when activity doesn't exist."""
        # Given
        event = {
            'pathParameters': {'id': 'nonexistent'},
            'requestContext': {
                'authorizer': {
                    'claims': {'custom:tenantId': 'tenant-123'}
                }
            }
        }
        
        mock_dynamodb_table.get_item.return_value = {}  # No Item key
        
        # When
        with patch('src.python.lambdas.activity.handler.table', mock_dynamodb_table):
            response = handler.lambda_handler(event, None)
        
        # Then
        assert response['statusCode'] == 404
        body = json.loads(response['body'])
        assert 'not found' in body['error'].lower()
    
    def test_should_return_500_when_dynamodb_error(self, mock_dynamodb_table):
        """Test 500 response on DynamoDB error."""
        # Given
        event = {
            'pathParameters': {'id': 'activity-123'},
            'requestContext': {
                'authorizer': {
                    'claims': {'custom:tenantId': 'tenant-123'}
                }
            }
        }
        
        mock_dynamodb_table.get_item.side_effect = ClientError(
            {'Error': {'Code': 'InternalServerError', 'Message': 'Service error'}},
            'GetItem'
        )
        
        # When
        with patch('src.python.lambdas.activity.handler.table', mock_dynamodb_table):
            response = handler.lambda_handler(event, None)
        
        # Then
        assert response['statusCode'] == 500
    
    @pytest.mark.parametrize('missing_field', [
        'pathParameters',
        'requestContext'
    ])
    def test_should_return_400_when_missing_required_fields(
        self, 
        mock_dynamodb_table, 
        missing_field
    ):
        """Test 400 response when required fields are missing."""
        # Given
        event = {
            'pathParameters': {'id': 'activity-123'},
            'requestContext': {
                'authorizer': {
                    'claims': {'custom:tenantId': 'tenant-123'}
                }
            }
        }
        del event[missing_field]
        
        # When
        with patch('src.python.lambdas.activity.handler.table', mock_dynamodb_table):
            response = handler.lambda_handler(event, None)
        
        # Then
        assert response['statusCode'] == 400
```

### Fixtures (conftest.py)

```python
"""
Shared test fixtures for Lambda tests.
"""
import pytest
from unittest.mock import Mock, MagicMock
from decimal import Decimal


@pytest.fixture
def mock_dynamodb_table():
    """Mock DynamoDB table."""
    table = MagicMock()
    table.get_item = Mock()
    table.put_item = Mock()
    table.query = Mock()
    table.scan = Mock()
    table.update_item = Mock()
    table.delete_item = Mock()
    return table


@pytest.fixture
def sample_activity():
    """Sample activity data."""
    return {
        'tenantId': 'tenant-123',
        'activityId': 'activity-123',
        'name': 'Office Electricity',
        'type': 'energy',
        'versionId': Decimal('1'),
        'createdAt': '2024-01-01T00:00:00Z',
        'updatedAt': '2024-01-02T00:00:00Z'
    }


@pytest.fixture
def sample_event():
    """Sample API Gateway event."""
    return {
        'httpMethod': 'GET',
        'path': '/activities/activity-123',
        'pathParameters': {'id': 'activity-123'},
        'queryStringParameters': None,
        'headers': {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer token123'
        },
        'body': None,
        'requestContext': {
            'authorizer': {
                'claims': {
                    'custom:tenantId': 'tenant-123',
                    'sub': 'user-456',
                    'email': 'user@example.com'
                }
            },
            'requestId': 'request-789'
        }
    }


@pytest.fixture
def mock_context():
    """Mock Lambda context."""
    context = Mock()
    context.function_name = 'test-function'
    context.function_version = '$LATEST'
    context.invoked_function_arn = 'arn:aws:lambda:us-east-1:123456789:function:test'
    context.memory_limit_in_mb = 128
    context.aws_request_id = 'test-request-id'
    context.log_group_name = '/aws/lambda/test-function'
    context.log_stream_name = '2024/01/01/[$LATEST]test'
    
    # Mock logger
    context.get_remaining_time_in_millis = Mock(return_value=30000)
    logger = Mock()
    logger.log = Mock()
    context.log = logger.log
    
    return context


@pytest.fixture(autouse=True)
def mock_environment_variables(monkeypatch):
    """Set up test environment variables."""
    monkeypatch.setenv('ACTIVITY_TABLE_NAME', 'Activity-test')
    monkeypatch.setenv('REPORT_TABLE_NAME', 'Report-test')
    monkeypatch.setenv('AWS_REGION', 'us-east-1')
    monkeypatch.setenv('STAGE', 'test')
```

## Mocking AWS Services with Moto

### DynamoDB Mocking

```python
"""
Integration test with moto for DynamoDB.
"""
import pytest
import boto3
from moto import mock_dynamodb


@mock_dynamodb
class TestDynamoDBOperations:
    """Test DynamoDB operations with moto."""
    
    @pytest.fixture(autouse=True)
    def setup_dynamodb(self):
        """Set up DynamoDB table for tests."""
        # Create mock DynamoDB resource
        self.dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
        
        # Create table
        self.table = self.dynamodb.create_table(
            TableName='Activity-test',
            KeySchema=[
                {'AttributeName': 'tenantId', 'KeyType': 'HASH'},
                {'AttributeName': 'activityId', 'KeyType': 'RANGE'}
            ],
            AttributeDefinitions=[
                {'AttributeName': 'tenantId', 'AttributeType': 'S'},
                {'AttributeName': 'activityId', 'AttributeType': 'S'}
            ],
            BillingMode='PAY_PER_REQUEST'
        )
        
        yield
        
        # Cleanup
        self.table.delete()
    
    def test_should_save_and_retrieve_item(self):
        """Test saving and retrieving item from DynamoDB."""
        # Given
        item = {
            'tenantId': 'tenant-123',
            'activityId': 'activity-456',
            'name': 'Test Activity'
        }
        
        # When
        self.table.put_item(Item=item)
        response = self.table.get_item(
            Key={
                'tenantId': 'tenant-123',
                'activityId': 'activity-456'
            }
        )
        
        # Then
        assert 'Item' in response
        assert response['Item']['name'] == 'Test Activity'
    
    def test_should_query_by_partition_key(self):
        """Test querying items by partition key."""
        # Given
        items = [
            {'tenantId': 'tenant-123', 'activityId': 'act-1', 'name': 'Activity 1'},
            {'tenantId': 'tenant-123', 'activityId': 'act-2', 'name': 'Activity 2'},
            {'tenantId': 'tenant-456', 'activityId': 'act-3', 'name': 'Activity 3'}
        ]
        
        for item in items:
            self.table.put_item(Item=item)
        
        # When
        response = self.table.query(
            KeyConditionExpression='tenantId = :tid',
            ExpressionAttributeValues={':tid': 'tenant-123'}
        )
        
        # Then
        assert response['Count'] == 2
        names = [item['name'] for item in response['Items']]
        assert 'Activity 1' in names
        assert 'Activity 2' in names
```

### S3 Mocking

```python
from moto import mock_s3

@mock_s3
def test_should_upload_file_to_s3():
    """Test S3 file upload."""
    # Given
    s3 = boto3.client('s3', region_name='us-east-1')
    bucket_name = 'test-bucket'
    s3.create_bucket(Bucket=bucket_name)
    
    # When
    s3.put_object(
        Bucket=bucket_name,
        Key='test.txt',
        Body=b'test content'
    )
    
    # Then
    response = s3.get_object(Bucket=bucket_name, Key='test.txt')
    content = response['Body'].read()
    assert content == b'test content'
```

## Parametrized Tests

```python
@pytest.mark.parametrize('activity_type,expected_category', [
    ('energy', 'scope2'),
    ('water', 'scope3'),
    ('waste', 'scope3'),
    ('transport', 'scope1')
])
def test_should_categorize_activity_correctly(activity_type, expected_category):
    """Test activity categorization logic."""
    # Given
    activity = {'type': activity_type}
    
    # When
    category = categorize_activity(activity)
    
    # Then
    assert category == expected_category


@pytest.mark.parametrize('input_value,expected_error', [
    (None, ValidationException),
    ('', ValidationException),
    ('   ', ValidationException),
    (-1, ValidationException)
], ids=['null', 'empty', 'whitespace', 'negative'])
def test_should_raise_validation_error(input_value, expected_error):
    """Test validation error handling."""
    with pytest.raises(expected_error):
        validate_input(input_value)
```

## Testing with Time

```python
from freezegun import freeze_time
from datetime import datetime

@freeze_time("2024-01-01 12:00:00")
def test_should_set_correct_timestamp():
    """Test timestamp generation."""
    # Given & When
    timestamp = generate_timestamp()
    
    # Then
    assert timestamp == "2024-01-01T12:00:00Z"


@freeze_time("2024-01-01")
def test_should_filter_by_date():
    """Test date filtering."""
    # Given
    activities = [
        {'date': '2024-01-01', 'name': 'Today'},
        {'date': '2023-12-31', 'name': 'Yesterday'}
    ]
    
    # When
    today_activities = filter_by_today(activities)
    
    # Then
    assert len(today_activities) == 1
    assert today_activities[0]['name'] == 'Today'
```

## Testing HTTP Requests

```python
import responses

@responses.activate
def test_should_call_external_api():
    """Test external API call."""
    # Given
    responses.add(
        responses.GET,
        'https://api.example.com/data',
        json={'result': 'success'},
        status=200
    )
    
    # When
    result = call_external_api()
    
    # Then
    assert result['result'] == 'success'
    assert len(responses.calls) == 1
    assert responses.calls[0].request.url == 'https://api.example.com/data'
```

## Async Testing

```python
import pytest

@pytest.mark.asyncio
async def test_async_handler():
    """Test async Lambda handler."""
    # Given
    event = {'data': 'test'}
    
    # When
    result = await async_handler(event, None)
    
    # Then
    assert result['statusCode'] == 200
```

## Test Coverage

### Pytest Configuration (pytest.ini)

```ini
[pytest]
testpaths = test
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts =
    --verbose
    --cov=src
    --cov-report=html
    --cov-report=term-missing
    --cov-fail-under=80
    --strict-markers
markers =
    unit: Unit tests (fast, no external dependencies)
    integration: Integration tests (slower, may use moto)
    slow: Slow tests
    smoke: Smoke tests for quick validation
```

### Running Tests

```bash
# All tests
pytest

# Unit tests only
pytest -m unit

# Integration tests
pytest -m integration

# With coverage
pytest --cov=src --cov-report=html

# Specific test file
pytest test/python/lambdas/activity/test_handler.py

# Specific test function
pytest test/python/lambdas/activity/test_handler.py::TestActivityGetHandler::test_should_return_activity_when_found

# Verbose output
pytest -v

# Stop on first failure
pytest -x

# Show print statements
pytest -s
```

## Test Organization Best Practices

### Test Class Structure

```python
class TestActivityHandler:
    """Tests for activity handler."""
    
    class TestGet:
        """Tests for GET operations."""
        
        def test_should_return_activity_when_found(self):
            pass
        
        def test_should_return_404_when_not_found(self):
            pass
    
    class TestCreate:
        """Tests for CREATE operations."""
        
        def test_should_create_activity_with_valid_data(self):
            pass
        
        def test_should_return_400_when_invalid_data(self):
            pass
```

### Test Naming

```python
# Pattern: test_should_ExpectedBehavior_when_StateUnderTest

def test_should_return_200_when_activity_found():
    pass

def test_should_raise_validation_error_when_name_is_empty():
    pass

def test_should_increment_version_when_activity_updated():
    pass
```

## Debugging Tests

```python
# Use pytest's built-in debugger
pytest --pdb  # Drop into debugger on failure

# Use pytest's trace
import pdb; pdb.set_trace()  # In test code

# Print debugging
pytest -s  # Show print statements

# Capture warnings
pytest -W error  # Turn warnings into errors
```

## Common Testing Patterns

### Testing Exceptions

```python
def test_should_raise_not_found_exception():
    """Test exception raising."""
    with pytest.raises(NotFoundException) as exc_info:
        get_nonexistent_activity()
    
    assert "Activity not found" in str(exc_info.value)
    assert exc_info.value.status_code == 404
```

### Testing Logs

```python
def test_should_log_error_message(caplog):
    """Test logging output."""
    # Given
    with caplog.at_level(logging.ERROR):
        # When
        process_with_error()
    
    # Then
    assert "Error processing" in caplog.text
    assert any(record.levelname == "ERROR" for record in caplog.records)
```

## Related Skills

- [nuoa-python](../nuoa-python/SKILL.md): Python development patterns
- [testing](../testing/SKILL.md): General testing strategies
- [nuoa-testing-java](../nuoa-testing-java/SKILL.md): Java testing patterns
- [nuoa-call-tenant](../nuoa-call-tenant/SKILL.md): API testing script
