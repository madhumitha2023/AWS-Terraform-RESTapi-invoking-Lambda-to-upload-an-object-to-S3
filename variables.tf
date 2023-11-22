variable "region" {
  description = "The AWS region where resources will be created."
  default = "eu-central-1"
}

variable "account_id" {
  description = "The AWS account ID where resources will be created."
  default = "411658317626"
}

variable "bucket_name" {
  description = "The name of the S3 Bucket."
  default = "metrogrp3-s3-bucket"
}

variable "deployment_package_path" {
  description = "The path to the Lambda deployment package"
  type        = string
  default     = "s3_operations_lambda_function.zip"
}

variable "lambda_function_name" {
  description = "The name of the Lambda function."
  default = "S3OperationsLambda"
}

variable "lambda_handler" {
  description = "The Lambda handler function."
  default = "S3OperationsLambdaFunction.lambda_handler"
}

variable "api_name" {
  description = "The name of the API Gateway."
  default     = "S3OperationsRESTapi"
}

variable "api_resource_path" {
  description = "The path for the API resource."
  default     = "S3OperationsResource"
}

variable "http_method" {
  description = "The HTTP method for the API Gateway method."
  default     = "POST"
}