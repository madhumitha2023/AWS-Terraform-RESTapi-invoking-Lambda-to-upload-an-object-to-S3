import boto3
import json

s3 = boto3.client('s3')

def lambda_handler(event, context):
    bucket_name = 'metrogrp3-s3-bucket'
    file_name = 'metrogrp3.txt' 
    content = 'Hello, this is an example content from metro college group3.'

    s3.put_object(Bucket=bucket_name, Key=file_name, Body=content)

    return {
        'statusCode': 200,
        'body': json.dumps('File uploaded to S3 successfully!')
    }

