#!/usr/bin/env python3
"""
AWS Resource Name Detection Script
Detects and lists AWS resources across different services using boto3
"""

import argparse
import sys
from typing import Dict, List, Any
import boto3
from botocore.exceptions import ClientError, NoCredentialsError, ProfileNotFound


class AWSResourceDetector:
    """Detects AWS resource names across various services"""
    
    def __init__(self, profile: str = None, region: str = None):
        """
        Initialize the AWS Resource Detector
        
        Args:
            profile: AWS profile name (optional)
            region: AWS region (optional, defaults to profile's default region)
        """
        self.session = boto3.Session(profile_name=profile, region_name=region)
        self.region = region or self.session.region_name
        
    def detect_lambda_functions(self) -> List[Dict[str, Any]]:
        """Detect Lambda function names"""
        try:
            client = self.session.client('lambda')
            response = client.list_functions()
            
            functions = []
            for func in response.get('Functions', []):
                functions.append({
                    'name': func['FunctionName'],
                    'runtime': func.get('Runtime', 'N/A'),
                    'arn': func['FunctionArn'],
                    'last_modified': func['LastModified']
                })
            
            return functions
        except ClientError as e:
            print(f"Error detecting Lambda functions: {e}")
            return []
    
    def detect_s3_buckets(self) -> List[Dict[str, Any]]:
        """Detect S3 bucket names"""
        try:
            client = self.session.client('s3')
            response = client.list_buckets()
            
            buckets = []
            for bucket in response.get('Buckets', []):
                buckets.append({
                    'name': bucket['Name'],
                    'creation_date': bucket['CreationDate'].isoformat()
                })
            
            return buckets
        except ClientError as e:
            print(f"Error detecting S3 buckets: {e}")
            return []
    
    def detect_dynamodb_tables(self) -> List[Dict[str, Any]]:
        """Detect DynamoDB table names"""
        try:
            client = self.session.client('dynamodb')
            response = client.list_tables()
            
            tables = []
            for table_name in response.get('TableNames', []):
                # Get additional details
                try:
                    table_info = client.describe_table(TableName=table_name)
                    table = table_info['Table']
                    tables.append({
                        'name': table_name,
                        'status': table.get('TableStatus', 'N/A'),
                        'item_count': table.get('ItemCount', 0),
                        'size_bytes': table.get('TableSizeBytes', 0)
                    })
                except ClientError:
                    tables.append({'name': table_name, 'status': 'Unknown'})
            
            return tables
        except ClientError as e:
            print(f"Error detecting DynamoDB tables: {e}")
            return []
    
    def detect_cloudformation_stacks(self) -> List[Dict[str, Any]]:
        """Detect CloudFormation stack names"""
        try:
            client = self.session.client('cloudformation')
            response = client.list_stacks(
                StackStatusFilter=[
                    'CREATE_COMPLETE', 'UPDATE_COMPLETE', 'UPDATE_ROLLBACK_COMPLETE',
                    'IMPORT_COMPLETE', 'IMPORT_ROLLBACK_COMPLETE'
                ]
            )
            
            stacks = []
            for stack in response.get('StackSummaries', []):
                stacks.append({
                    'name': stack['StackName'],
                    'status': stack['StackStatus'],
                    'creation_time': stack['CreationTime'].isoformat()
                })
            
            return stacks
        except ClientError as e:
            print(f"Error detecting CloudFormation stacks: {e}")
            return []
    
    def detect_api_gateways(self) -> List[Dict[str, Any]]:
        """Detect API Gateway names"""
        try:
            client = self.session.client('apigateway')
            response = client.get_rest_apis()
            
            apis = []
            for api in response.get('items', []):
                apis.append({
                    'name': api['name'],
                    'id': api['id'],
                    'created_date': api.get('createdDate', 'N/A')
                })
            
            return apis
        except ClientError as e:
            print(f"Error detecting API Gateways: {e}")
            return []
    
    def detect_all_resources(self) -> Dict[str, List[Dict[str, Any]]]:
        """Detect all supported AWS resources"""
        return {
            'lambda_functions': self.detect_lambda_functions(),
            's3_buckets': self.detect_s3_buckets(),
            'dynamodb_tables': self.detect_dynamodb_tables(),
            'cloudformation_stacks': self.detect_cloudformation_stacks(),
            'api_gateways': self.detect_api_gateways()
        }
    
    def print_resources(self, resources: Dict[str, List[Dict[str, Any]]]):
        """Print detected resources in a formatted way"""
        print(f"\n{'='*80}")
        print(f"AWS Resources in Region: {self.region}")
        print(f"{'='*80}\n")
        
        for resource_type, items in resources.items():
            print(f"\n{resource_type.upper().replace('_', ' ')} ({len(items)} found):")
            print(f"{'-'*80}")
            
            if not items:
                print("  No resources found")
                continue
            
            for idx, item in enumerate(items, 1):
                print(f"\n  {idx}. {item.get('name', 'N/A')}")
                for key, value in item.items():
                    if key != 'name':
                        print(f"     {key}: {value}")


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description='Detect AWS resource names using boto3',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python detect_aws_resources.py --profile aws-beta
  python detect_aws_resources.py --profile aws-beta --region us-east-1
  python detect_aws_resources.py --profile aws-beta --service lambda
  python detect_aws_resources.py --profile aws-beta --service s3
        """
    )
    
    parser.add_argument(
        '--profile',
        type=str,
        help='AWS profile name to use'
    )
    
    parser.add_argument(
        '--region',
        type=str,
        help='AWS region (defaults to profile\'s default region)'
    )
    
    parser.add_argument(
        '--service',
        type=str,
        choices=['lambda', 's3', 'dynamodb', 'cloudformation', 'apigateway', 'all'],
        default='all',
        help='Specific AWS service to detect resources for (default: all)'
    )
    
    args = parser.parse_args()
    
    try:
        detector = AWSResourceDetector(profile=args.profile, region=args.region)
        
        if args.service == 'all':
            resources = detector.detect_all_resources()
            detector.print_resources(resources)
        else:
            service_map = {
                'lambda': ('lambda_functions', detector.detect_lambda_functions()),
                's3': ('s3_buckets', detector.detect_s3_buckets()),
                'dynamodb': ('dynamodb_tables', detector.detect_dynamodb_tables()),
                'cloudformation': ('cloudformation_stacks', detector.detect_cloudformation_stacks()),
                'apigateway': ('api_gateways', detector.detect_api_gateways())
            }
            
            resource_type, items = service_map[args.service]
            detector.print_resources({resource_type: items})
        
        return 0
        
    except NoCredentialsError:
        print("Error: AWS credentials not found. Please configure your AWS credentials.")
        return 1
    except ProfileNotFound as e:
        print(f"Error: AWS profile not found: {e}")
        return 1
    except Exception as e:
        print(f"Unexpected error: {e}")
        return 1


if __name__ == '__main__':
    sys.exit(main())
