terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.2.0"
}


provider "aws" {
  region = var.region
}


# S3 bucket to store static website files
resource "aws_s3_bucket" "static-website" {
  bucket = "steam-robotics-academy"
}



# Create origin access control for s3 origin
resource "aws_cloudfront_origin_access_control" "oac_s3" {
  name = "oac_s3"
  description = "Allow CloudFront to access the S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior = "always"
  signing_protocol = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "cloudfront_distribution" {
  default_root_object = "index.html"
  enabled = true
  is_ipv6_enabled = true
  price_class = "PriceClass_100"
  #http_version = "http2"

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.static-website.bucket
    viewer_protocol_policy = "allow-all"

    forwarded_values {
      cookies {
        forward = "none"
      }
      query_string = false
    }
  }
  
  origin {
    domain_name = aws_s3_bucket.static-website.bucket_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac_s3.id
    origin_id = aws_s3_bucket.static-website.bucket
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

}


# Bucket policy to allow access from cloudFront
resource "aws_s3_bucket_policy" "s3_allow_cloudfront" {
  bucket = aws_s3_bucket.static-website.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal",
        Effect    = "Allow",
        Principal = {
          "Service": "cloudfront.amazonaws.com"
        },
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.static-website.arn}/*",
        Condition = {
          StringEquals = {
            "AWS:SourceArn": "${aws_cloudfront_distribution.cloudfront_distribution.arn}"

          }
        }
      }
    ]
  })
}

# DynamoDB table to store user registrations
resource "aws_dynamodb_table" "usersDB" {
    name = "usersDB"
    hash_key = "user_id"
    billing_mode = "PAY_PER_REQUEST"

    attribute {
        name = "user_id"
        type = "S"
    }
}



# IAM role for Lambda to interact with DynamoDB
resource "aws_iam_role" "lambda_excecution" {
    name = "lambda_dynamodb_excecution_role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Effect = "Allow",
                Principal = {
                    Service = "lambda.amazonaws.com"
                },
                Action = "sts:AssumeRole"
            }
        ]
    })
  
}

# Lambda function to store user registrations in DynamoDB
resource "aws_lambda_function" "save_user_data" {
    function_name = "save_user_data"
    handler = "save_user_data.lambda_handler"
    runtime = "python3.9"
    role = aws_iam_role.lambda_excecution.arn
    filename = "lambda/save_user_data.zip"
}


# Attach policies to the lambda role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
    role = aws_iam_role.lambda_excecution.name
}

# IAM policy for Lambda to interact with DynamoDB
resource "aws_iam_role_policy" "lambda_policy" {
    name = "lambda_dynamodb_policy"
    role = aws_iam_role.lambda_excecution.id
    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Effect = "Allow",
                Action = [
                    "dynamodb:*"
                ],
                Resource = "${aws_dynamodb_table.usersDB.arn}"
            }
        ]
    })
}



# API creation
resource "aws_api_gateway_rest_api" "user_registration_api" {
    name = "user_registration_api"
    description = "API to handle registration form submission"
}


# API Gateway resource. All the requests will be sent to this resource
resource "aws_api_gateway_resource" "resource" {
    rest_api_id = aws_api_gateway_rest_api.user_registration_api.id
    parent_id = aws_api_gateway_rest_api.user_registration_api.root_resource_id
    path_part = "registration"
}


# API Gateway method
resource "aws_api_gateway_method" "method" {
    rest_api_id = aws_api_gateway_rest_api.user_registration_api.id
    resource_id = aws_api_gateway_resource.resource.id
    http_method = "POST"
    authorization = "NONE"
}

# API Gateway integration with lambda
resource "aws_api_gateway_integration" "integration" {
    rest_api_id = aws_api_gateway_rest_api.user_registration_api.id
    resource_id = aws_api_gateway_resource.resource.id
    http_method = aws_api_gateway_method.method.http_method
    integration_http_method = "POST"
    type = "AWS"
    uri = aws_lambda_function.save_user_data.invoke_arn
}

# API Gateway method response
resource "aws_api_gateway_method_response" "response" {
  rest_api_id = aws_api_gateway_rest_api.user_registration_api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = 200


}

# API permissions to invoque Lambda
resource "aws_lambda_permission" "api_gateway_invoke_lambda" {
    statement_id = "AllowAPIGatewayInvokeLambda"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.save_user_data.function_name
    principal = "apigateway.amazonaws.com"
    source_arn =  "${aws_api_gateway_rest_api.user_registration_api.execution_arn}/*/*/*" 
}

# Api deployment
resource "aws_api_gateway_deployment" "api-deployment" {
  rest_api_id = aws_api_gateway_rest_api.user_registration_api.id
  description = "Deployment for user registration API"
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.resource.id,
      aws_api_gateway_method.method.id,
      aws_api_gateway_integration.integration.id
    ]))
  }
  
}

resource "aws_api_gateway_stage" "api-stage" {
  deployment_id = aws_api_gateway_deployment.api-deployment.id
  rest_api_id = aws_api_gateway_rest_api.user_registration_api.id
  stage_name = "prod"
  
}

resource "aws_api_gateway_resource" "cors_resource" {
  rest_api_id = aws_api_gateway_rest_api.user_registration_api.id
  parent_id = aws_api_gateway_rest_api.user_registration_api.root_resource_id
  path_part = "{cors+}"
  
}

resource "aws_api_gateway_method" "cors_method" {
  rest_api_id = aws_api_gateway_rest_api.user_registration_api.id
  resource_id = aws_api_gateway_resource.cors_resource.id
  http_method = "OPTIONS"
  authorization = "NONE"
  
}

resource "aws_api_gateway_integration" "cors_integration" {
  rest_api_id = aws_api_gateway_rest_api.user_registration_api.id
  resource_id = aws_api_gateway_resource.cors_resource.id
  http_method = aws_api_gateway_method.cors_method.http_method
  type = "MOCK"
  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
  
}

resource "aws_api_gateway_method_response" "cors_response" {
  depends_on = [aws_api_gateway_method.cors_method]
  rest_api_id = aws_api_gateway_rest_api.user_registration_api.id
  resource_id = aws_api_gateway_resource.cors_resource.id
  http_method = aws_api_gateway_method.cors_method.http_method
  status_code = 200
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Headers" = true
  }
  response_models = {
    "application/json" = "Empty"
  }

}

resource "aws_api_gateway_integration_response" "cors_integration_response" {
  depends_on = [aws_api_gateway_integration.cors_integration, aws_api_gateway_method_response.cors_response]
  rest_api_id = aws_api_gateway_rest_api.user_registration_api.id
  resource_id = aws_api_gateway_resource.cors_resource.id
  http_method = aws_api_gateway_method.cors_method.http_method
  status_code = 200
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'",
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET, POST, OPTIONS'"
  }
  
}








