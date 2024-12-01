#!/bin/bash -eux

PROFILE=${AWS_PROFILE:+"--profile ${AWS_PROFILE}"}

echo "VERSION: ${VERSION:?}"
REPO="${AWS_ACCOUNT_ID:?}.dkr.ecr.ap-northeast-1.amazonaws.com"

# Login to ECR
aws $PROFILE ecr get-login-password --region ap-northeast-1 | \
    docker login --username AWS --password-stdin $REPO

# Tag image
docker tag img-resizer:latest $REPO/img-resizer:"$VERSION"

# Push image
docker push $REPO/img-resizer:"$VERSION"

# Tag and push latest if the VERSION is not *-SNAPSHOT
if [[ ! $VERSION == *-SNAPSHOT ]]; then
    docker tag img-resizer:latest $REPO/img-resizer:latest
    docker push $REPO/img-resizer:latest
fi
