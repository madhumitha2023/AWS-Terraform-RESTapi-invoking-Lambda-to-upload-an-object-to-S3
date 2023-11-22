output "invoke_url" {
  value = format("https://%s.execute-api.%s.amazonaws.com/test", aws_api_gateway_rest_api.my_api.id, var.region)

}

output "s3_bucket_name" {
  value = aws_s3_bucket.my_bucket.bucket
}

output "lambda_function_name" {
  value = aws_lambda_function.s3_operations_lambda.function_name
}
