import argparse
import boto3

def scan_and_update_table(table_name, aws_profile, dry_run=True):
    if aws_profile is not None:
        session = boto3.Session(profile_name=aws_profile)
        dynamodb = session.resource('dynamodb')
    else: # Use the default profile
        dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(table_name)

    response = None
    count = 0
    while response is None or 'LastEvaluatedKey' in response:
        response = table.scan() if response is None else table.scan(ExclusiveStartKey=response['LastEvaluatedKey'])
        for item in response['Items']:
            item['versionId'] = int(item['versionId']) + 1

            if dry_run:
                count += 1
                continue
            else:
                # Save the updated item back to the table
                print(f"Update: {item}")
                try:
                    table.put_item(
                        Item=item,
                        ConditionExpression='versionId < :value',
                        ExpressionAttributeValues={':value': item['versionId']}
                    )
                    count += 1
                except Exception as e:
                    print(f"Optimistic lock check failed: {e}")
        if dry_run:
            break
    print(f"Scanned and updated {count} rows.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--table-name', required=True, help='Name of the table')
    parser.add_argument('--dry-run', required=False, default=False, action='store_true', help='Perform a dry run')
    parser.add_argument('--aws-profile', required=False, default=None, help='AWS profile name')
    args = parser.parse_args()

    scan_and_update_table(args.table_name, args.aws_profile, args.dry_run)
