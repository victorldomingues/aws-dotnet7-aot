terraform {
  required_providers {
    aws = {
      version = "4.67.0"
      source  = "hashicorp/aws"
    }
  }
  backend "s3" {
    region = "us-east-1"
    bucket = "meu-bucket"
    key    = "meu-state-file"
  }
}


locals{
  zip = "../bootstrap.zip"
  lambda_name = "dotnet7-aot"
}

data "aws_s3_bucket" "api_bucket" {
  bucket = "domingues-vi-bucket-lambdas"
}

data "aws_iam_role" "api_lambda_role" {
  name = "dotnet-lambda-role"
}

resource "aws_s3_object" "api_code_archive" {
  bucket = data.aws_s3_bucket.api_bucket.id
  key    = "${local.lambda_name}.zip"
  source = local.zip
  etag   = filemd5(local.zip)
  lifecycle {
    ignore_changes = [
      etag,
      version_id
    ]
  }
}

resource "aws_lambda_function" "api_lambda" {
  function_name    = local.lambda_name
  role             = data.aws_iam_role.api_lambda_role.arn
  s3_bucket        = data.aws_s3_bucket.api_bucket.id
  s3_key           = aws_s3_object.api_code_archive.key
  source_code_hash = filemd5(local.zip)
  architectures    = ["arm64"]
  runtime          = "provided.al2"
  handler          = "bootstrap"
  memory_size      = 128
  publish          = true

  lifecycle {
    ignore_changes = [
      last_modified,
      source_code_hash,
      version,
      environment
    ]
  }
}

resource "aws_lambda_alias" "api_lambda_alias" {
  name             = "production"
  function_name    = aws_lambda_function.api_lambda.arn
  function_version = "$LATEST"

  lifecycle {
    ignore_changes = [
      function_version
    ]
  }
}

resource "aws_cloudwatch_log_group" "api_lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.api_lambda.function_name}"
  retention_in_days = 1
  tags              = {}
}
