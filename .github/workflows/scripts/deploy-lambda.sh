#!/bin/bash -eux

PROFILE=${AWS_PROFILE:+"--profile ${AWS_PROFILE}"}

echo "VERSION: ${VERSION:?}"
LAMBDA_FUNCTION_NAME="img-resizer"
REPO="${AWS_ACCOUNT_ID:?}.dkr.ecr.ap-northeast-1.amazonaws.com"

# Deploy lambda from ECR
aws ${PROFILE} lambda update-function-code \
  --function-name $LAMBDA_FUNCTION_NAME \
  --image-uri "${REPO}/${LAMBDA_FUNCTION_NAME}:${VERSION}" \
  --output json \
  --no-cli-pager

aws ${PROFILE} lambda wait function-updated-v2 \
  --function-name $LAMBDA_FUNCTION_NAME

echo "Deployed ${LAMBDA_FUNCTION_NAME}:${VERSION}"
