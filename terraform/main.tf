terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

variable "aws_profile" {
  type    = string
}

provider "aws" {
  region = "ap-northeast-1"
  profile = var.aws_profile
}

# ECR
# ============================================================================

resource "aws_ecr_repository" "img_resizer_repo" {
  name                 = "img-resizer"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# S3
# ============================================================================

# S3 bucket for images to be resized
resource "aws_s3_bucket" "img_from" {
  bucket = "img-from"
}

# S3 bucket for resized images
resource "aws_s3_bucket" "img_to" {
  bucket = "img-to"
}

# IAM
# ============================================================================

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "lambda_s3_from_access_policy" {
  statement {
    # Allow Lambda to read from S3
    # for debug: list objects in the bucket
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:ListObjects",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.img_from.arn,
      "${aws_s3_bucket.img_from.arn}/*",
    ]
  }
}
resource "aws_iam_policy" "lambda_s3_from_access_policy" {
  name        = "lambda_s3_from_access_policy"
  description = "Allow Lambda to read from S3"
  policy      = data.aws_iam_policy_document.lambda_s3_from_access_policy.json
}
resource "aws_iam_role_policy_attachment" "lambda_s3_from_access_policy_attachment" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_s3_from_access_policy.arn
}

data "aws_iam_policy_document" "lambda_s3_to_access_policy" {
  statement {
    # Allow Lambda to write to S3
    effect = "Allow"

    actions = [
      "s3:PutObject",
    ]

    resources = [
      aws_s3_bucket.img_to.arn,
      "${aws_s3_bucket.img_to.arn}/*",
    ]
  }
}
resource "aws_iam_policy" "lambda_s3_to_access_policy" {
  name        = "lambda_s3_to_access_policy"
  description = "Allow Lambda to write to S3"
  policy      = data.aws_iam_policy_document.lambda_s3_to_access_policy.json
}
resource "aws_iam_role_policy_attachment" "lambda_s3_to_access_policy_attachment" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_s3_to_access_policy.arn
}

# Lambda
# ============================================================================

resource "aws_lambda_function" "img_resizer_lambda" {
  function_name = "img-resizer"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.img_resizer_repo.repository_url}:latest"
  role          = aws_iam_role.iam_for_lambda.arn
  timeout       = 60

  lifecycle {
    ignore_changes = [image_uri]
  }
}
