# Configure AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "forum-app"
}

# Cognito User Pool
resource "aws_cognito_user_pool" "forum_users" {
  name = "${var.project_name}-users"

  username_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  auto_verified_attributes = ["email"]

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  schema {
    attribute_data_type = "String"
    name               = "email"
    required           = true
    mutable           = true
  }

  schema {
    attribute_data_type = "String"
    name               = "username"
    required           = true
    mutable           = false
  }

  tags = {
    Name = "${var.project_name}-user-pool"
  }
}

# Cognito User Pool Client - FIXED
resource "aws_cognito_user_pool_client" "forum_client" {
  name         = "${var.project_name}-client"
  user_pool_id = aws_cognito_user_pool.forum_users.id

  explicit_auth_flows = [
    "ADMIN_NO_SRP_AUTH",
    "USER_PASSWORD_AUTH",
    "ALLOW_ADMIN_USER_PASSWORD_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  generate_secret                = false
  prevent_user_existence_errors  = "ENABLED"
  enable_token_revocation       = true

  access_token_validity  = 60
  id_token_validity     = 60
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
}

# S3 Bucket for file uploads
resource "aws_s3_bucket" "forum_uploads" {
  bucket = "${var.project_name}-uploads-${random_string.bucket_suffix.result}"

  tags = {
    Name = "${var.project_name}-uploads"
  }
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "forum_uploads_versioning" {
  bucket = aws_s3_bucket.forum_uploads.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "forum_uploads_encryption" {
  bucket = aws_s3_bucket.forum_uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "forum_uploads_cors" {
  bucket = aws_s3_bucket.forum_uploads.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "POST", "PUT", "DELETE"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# DynamoDB Tables
resource "aws_dynamodb_table" "posts" {
  name           = "${var.project_name}-posts"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  global_secondary_index {
    name     = "created-at-index"
    hash_key = "created_at"
    projection_type = "ALL"
  }

  tags = {
    Name = "${var.project_name}-posts"
  }
}

# Comments Table - FIXED
resource "aws_dynamodb_table" "comments" {
  name           = "${var.project_name}-comments"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "post_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  global_secondary_index {
    name               = "post-id-index"
    hash_key          = "post_id"
    range_key         = "created_at"
    projection_type   = "ALL"
  }

  tags = {
    Name = "${var.project_name}-comments"
  }
}

resource "aws_dynamodb_table" "votes" {
  name           = "${var.project_name}-votes"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "post_id"
    type = "S"
  }

  global_secondary_index {
    name     = "user-id-index"
    hash_key = "user_id"
    projection_type = "ALL"
  }

  global_secondary_index {
    name     = "post-id-index"
    hash_key = "post_id"
    projection_type = "ALL"
  }

  tags = {
    Name = "${var.project_name}-votes"
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.posts.arn,
          aws_dynamodb_table.comments.arn,
          aws_dynamodb_table.votes.arn,
          "${aws_dynamodb_table.posts.arn}/index/*",
          "${aws_dynamodb_table.comments.arn}/index/*",
          "${aws_dynamodb_table.votes.arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.forum_uploads.arn}/*"
      }
    ]
  })
}

# Lambda Function
resource "aws_lambda_function" "forum_api" {
  filename         = "forum-api.zip"
  function_name    = "${var.project_name}-api"
  role            = aws_iam_role.lambda_role.arn
  handler         = "forum-api.handler"
  runtime         = "nodejs18.x"
  timeout         = 30

  source_code_hash = filebase64sha256("forum-api.zip")

  environment {
    variables = {
      POSTS_TABLE = aws_dynamodb_table.posts.name
      COMMENTS_TABLE = aws_dynamodb_table.comments.name
      VOTES_TABLE = aws_dynamodb_table.votes.name
      S3_BUCKET = aws_s3_bucket.forum_uploads.bucket
    }
  }

  depends_on = [aws_iam_role_policy.lambda_policy]
}

# API Gateway - FIXED (removed cors_configuration)
resource "aws_api_gateway_rest_api" "forum_api" {
  name        = "${var.project_name}-api"
  description = "Forum API Gateway"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.forum_api.id
  parent_id   = aws_api_gateway_rest_api.forum_api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.forum_api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.forum_api.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.forum_api.invoke_arn
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.forum_api.id
  resource_id   = aws_api_gateway_rest_api.forum_api.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.forum_api.id
  resource_id = aws_api_gateway_method.proxy_root.resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.forum_api.invoke_arn
}

resource "aws_api_gateway_deployment" "forum_api" {
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_root,
  ]

  rest_api_id = aws_api_gateway_rest_api.forum_api.id
  stage_name  = "prod"
}

# Enable CORS
resource "aws_api_gateway_method" "options" {
  rest_api_id   = aws_api_gateway_rest_api.forum_api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options" {
  rest_api_id = aws_api_gateway_rest_api.forum_api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options" {
  rest_api_id = aws_api_gateway_rest_api.forum_api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options" {
  rest_api_id = aws_api_gateway_rest_api.forum_api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = aws_api_gateway_method_response.options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.forum_api.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.forum_api.execution_arn}/*/*"
}

# Outputs
output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.forum_users.id
}

output "cognito_client_id" {
  value = aws_cognito_user_pool_client.forum_client.id
}

output "api_gateway_url" {
  value = aws_api_gateway_deployment.forum_api.invoke_url
}

output "s3_bucket_name" {
  value = aws_s3_bucket.forum_uploads.bucket
}