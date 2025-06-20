output "user_pool_id" {
  value = aws_cognito_user_pool.forum_user_pool.id
}

output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.forum_client.id
}

output "identity_pool_id" {
  value = aws_cognito_identity_pool.forum_identity_pool.id
}

output "api_gateway_url" {
  value = aws_api_gateway_deployment.forum_api.invoke_url
}

output "s3_bucket_name" {
  value = aws_s3_bucket.forum_uploads.bucket
}

output "aws_region" {
  value = var.aws_region
}