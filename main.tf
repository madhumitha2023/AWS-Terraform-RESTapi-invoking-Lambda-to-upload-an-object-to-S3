terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1" 
  access_key = "AKIAV7WF7N45BRLGZEOD"
  secret_key = "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"
}

resource "aws_iam_role" "lambda_role" {
  name = "Lambda_ExecutionRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_role_policy_attachment" "s3_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_role_policy_attachment" "additional_policies" {
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_role_policy_attachment" "dynamodb_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
  role       = aws_iam_role.lambda_role.name
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = var.bucket_name
  
  

}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.my_bucket.id

  
  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "my_bucket_policy" {
  bucket = aws_s3_bucket.my_bucket.bucket
  
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:PutBucketPolicy"
      ],
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.my_bucket.bucket}/*",
        "arn:aws:s3:::${aws_s3_bucket.my_bucket.bucket}"
      ],
      "Principal": "*"
    }
  ]
}
EOF
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/s3file"  
  output_path = "${path.module}/s3_operations_lambda_function.zip"
}

resource "aws_s3_bucket_object" "lambda_function_zip" {
  bucket = aws_s3_bucket.my_bucket.bucket
  key    = "s3_operations_lambda_function.zip"
  acl    = "private"
  source = data.archive_file.lambda_zip.output_path
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name = "/aws/lambda/S3OperationsLambda"
}

resource "aws_lambda_function" "s3_operations_lambda" {
  function_name    = var.lambda_function_name
  runtime          = "python3.9"
  handler          = var.lambda_handler
  role             = aws_iam_role.lambda_role.arn
  publish          = true
  filename         = aws_s3_bucket_object.lambda_function_zip.source
  source_code_hash = aws_s3_bucket_object.lambda_function_zip.etag
  
  # Add the CloudWatch Logs configuration
  tracing_config {
    mode = "PassThrough"
  }

  depends_on = [aws_cloudwatch_log_group.lambda_log_group]
}

resource "aws_api_gateway_rest_api" "my_api" {
  name        = var.api_name
  description = "REST API for S3 Operations"
}

resource "aws_api_gateway_resource" "api_resource" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id   = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part   = var.api_resource_path
}

resource "aws_api_gateway_method" "api_method" {
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.api_resource.id
  http_method   = var.http_method
  authorization = "NONE"
}

resource "aws_lambda_permission" "api_gateway_invoke_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_operations_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  
   # Add source_arn to specify the ARN of your API Gateway resource
  source_arn    = "arn:aws:execute-api:${var.region}:${var.account_id}:${aws_api_gateway_rest_api.my_api.id}/*/POST/S3OperationsResource"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.my_api.id
  resource_id             = aws_api_gateway_resource.api_resource.id
  http_method             = aws_api_gateway_method.api_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.s3_operations_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "my_deployment" {
  depends_on      = [aws_api_gateway_integration.lambda_integration]
  rest_api_id      = aws_api_gateway_rest_api.my_api.id
  stage_name       = "test"
}




