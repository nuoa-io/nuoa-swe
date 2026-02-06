#!/usr/bin/env python3
"""
Get Lambda functions filtered by domain and stage.
"""
import argparse
import boto3
from botocore.exceptions import ClientError, NoCredentialsError


def parse_args():
    parser = argparse.ArgumentParser(description='List AWS Lambda functions by domain and stage')
    parser.add_argument('--domain', help='Domain name (e.g., reportmanagement, activitymanagement)')
    parser.add_argument('--stage', help='Stage (beta, prod, gamma)')
    parser.add_argument('--profile', required=True, help='AWS profile name (e.g., nuoa, nuoa-beta)')
    return parser.parse_args()


def get_lambdas(profile_name, domain=None, stage=None):
    try:
        session = boto3.Session(profile_name=profile_name)
        lambda_client = session.client('lambda')
        
        print(f"Fetching Lambda functions (Profile: {profile_name})...")
        
        paginator = lambda_client.get_paginator('list_functions')
        functions = []
        
        for page in paginator.paginate():
            for func in page['Functions']:
                func_name = func['FunctionName']
                
                # Filter by domain and stage if provided
                if domain and domain.lower() not in func_name.lower():
                    continue
                if stage and stage.lower() not in func_name.lower():
                    continue
                    
                functions.append(func_name)
        
        if functions:
            print(f"\nFound {len(functions)} Lambda function(s):\n")
            for func in sorted(functions):
                print(f"  • {func}")
        else:
            print("\nNo Lambda functions found matching the criteria.")
            
        return functions
        
    except NoCredentialsError:
        print(f"Error: AWS credentials not found for profile '{profile_name}'")
        print("Please configure credentials in ~/.aws/credentials")
        return []
    except ClientError as e:
        print(f"Error accessing AWS: {e}")
        return []
    except Exception as e:
        print(f"Unexpected error: {e}")
        return []


if __name__ == '__main__':
    args = parse_args()
    get_lambdas(args.profile, args.domain, args.stage)
