#!/usr/bin/env python3
"""
Get CloudWatch logs for a Lambda function.
"""
import argparse
import boto3
from datetime import datetime, timedelta
from botocore.exceptions import ClientError, NoCredentialsError


def parse_args():
    parser = argparse.ArgumentParser(description='Fetch CloudWatch logs for Lambda function')
    parser.add_argument('--function', required=True, help='Lambda function name')
    parser.add_argument('--time', default='5m', help='Time range (e.g., 1m, 5m, 10m, 1h)')
    parser.add_argument('--profile', required=True, help='AWS profile name (e.g., nuoa, nuoa-beta)')
    return parser.parse_args()


def parse_time_range(time_str):
    """Convert time string (e.g., '5m', '1h') to timedelta."""
    unit = time_str[-1].lower()
    value = int(time_str[:-1])
    
    if unit == 'm':
        return timedelta(minutes=value)
    elif unit == 'h':
        return timedelta(hours=value)
    elif unit == 'd':
        return timedelta(days=value)
    else:
        raise ValueError(f"Invalid time unit: {unit}. Use m (minutes), h (hours), or d (days)")


def get_logs(profile_name, function_name, time_range):
    try:
        session = boto3.Session(profile_name=profile_name)
        logs_client = session.client('logs')
        
        log_group_name = f"/aws/lambda/{function_name}"
        
        end_time = datetime.utcnow()
        start_time = end_time - parse_time_range(time_range)
        
        print(f"Fetching logs for '{function_name}' (Profile: {profile_name})")
        print(f"Time range: {time_range} ({start_time.strftime('%Y-%m-%d %H:%M:%S')} to {end_time.strftime('%Y-%m-%d %H:%M:%S')} UTC)\n")
        
        start_ms = int(start_time.timestamp() * 1000)
        end_ms = int(end_time.timestamp() * 1000)
        
        events = []
        kwargs = {
            'logGroupName': log_group_name,
            'startTime': start_ms,
            'endTime': end_ms,
            'limit': 100
        }
        
        while True:
            response = logs_client.filter_log_events(**kwargs)
            events.extend(response.get('events', []))
            
            next_token = response.get('nextToken')
            if not next_token or len(events) >= 100:
                break
            kwargs['nextToken'] = next_token
        
        if events:
            print(f"Found {len(events)} log event(s):\n")
            print("=" * 80)
            for event in events[:100]:
                timestamp = datetime.fromtimestamp(event['timestamp'] / 1000)
                print(f"[{timestamp.strftime('%Y-%m-%d %H:%M:%S')}] {event['message']}")
            print("=" * 80)
        else:
            print("No log events found in the specified time range.")
            
        return events
        
    except NoCredentialsError:
        print(f"Error: AWS credentials not found for profile '{profile_name}'")
        print("Please configure credentials in ~/.aws/credentials")
        return []
    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == 'ResourceNotFoundException':
            print(f"Error: Log group '{log_group_name}' not found.")
            print("Make sure the Lambda function name is correct.")
        else:
            print(f"Error accessing AWS: {e}")
        return []
    except ValueError as e:
        print(f"Error: {e}")
        return []
    except Exception as e:
        print(f"Unexpected error: {e}")
        return []


if __name__ == '__main__':
    args = parse_args()
    get_logs(args.profile, args.function, args.time)
